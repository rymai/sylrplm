#--
# Copyright (c) 2008-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

require 'openwfe/representations'

class WorkitemsController < ApplicationController
  include Controllers::PlmObjectControllerModule

  access_control(Access.find_for_controller(controller_class_name))
  # GET /workitems
  #  or
  # GET /workitems?q=:q || GET /workitems?query=:q
  #  or
  # GET /workitems?p=:p || GET /workitems?participant=:p
  #
  def index
    #    puts "workitems_controller.index:params="+params.inspect
    @query = params[:q] || params[:query]
    @workitems = if @query
      OpenWFE::Extras::ArWorkitem.search(
      @query,
      @current_user.store_names)
      #TODO syl @current_user.is_admin? ? nil : @current_user.store_names)
      # TODO : paginate that !

    else

      opts = { :order => 'dispatch_time DESC' }
      opts[:conditions] = { :store_name => @current_user.store_names }
      #TODO syl opts[:conditions] = { :store_name => @current_user.store_names } \
      #unless @current_user.is_admin?
      opts[:page] = (params[:page].nil? ? SYLRPLM::NB_ITEMS_PER_PAGE :  params[:page])
      #      puts "workitems_controller.index:page="+opts[:page].inspect
      OpenWFE::Extras::ArWorkitem.paginate_by_params(
      [
        # parameter_name[, column_name]
        'wfid',
        [ 'workflow', 'wfname' ],
        [ 'store', 'store_name' ],
        [ 'participant', 'participant_name' ]
      ],
      params,
      opts)
    end

    # TODO : escape pagination for XML and JSON ??

    respond_to do |format|

      format.html
      # => app/views/workitems/index.html.erb

      format.json do
        render(:json => OpenWFE::Json.workitems_to_h(
        @workitems,
        :linkgen => linkgen).to_json)
      end

      format.xml do
        render(:xml => OpenWFE::Xml.workitems_to_xml(
        @workitems,
        :indent => 2, :linkgen => linkgen))
      end
    end
  end

  # GET /workitems/:wfid/:expid/edit
  #
  def edit
    #    puts "workitems_controller.edit:params="+params.inspect
    @workitem = find_ar_workitem
    get_wi_links(@workitem)
    @payload_partial = determine_payload_partial(@workitem)

    return error_reply('no workitem', 404) unless @workitem

    # only responds in HTML...
  end

  # GET /workitems/:wfid/:expid
  #
  def show
    #    puts "workitems_controller.show:params="+params.inspect
    @workitem = find_ar_workitem
    get_wi_links(@workitem)
    @payload_partial = determine_payload_partial(@workitem)

    return error_reply('no workitem', 404) unless @workitem

    respond_to do |format|
      format.html # => app/views/show.html.erb
      format.json { render :json => OpenWFE::Json.workitem_to_h(
        @workitem, :linkgen => linkgen).to_json }
      format.xml { render :xml => OpenWFE::Xml.workitem_to_xml(
        @workitem, :indent => 2, :linkgen => linkgen) }
    end
  end

  # PUT /workitems/:wfid/:expid
  #
  def update

    #    puts "workitems_controller.update:params="+params.inspect
    # select du ArWorkitem
    ar_workitem = find_ar_workitem
    return error_reply('no workitem', 404) unless ar_workitem
    puts "workitems_controller.update:ar_workitem="+ar_workitem.inspect
    puts "workitems_controller.update:keywords="+ar_workitem.keywords.inspect
    puts "workitems_controller.update:state="+params[:state].to_s+" store_name="+params[:store_name].to_s
    # creation du InFlowWorkItem depuis le ar_workitem
    in_flow_workitem = ar_workitem.to_owfe_workitem
    puts "workitems_controller.update:in_flow_workitem="+in_flow_workitem.inspect
    # get WorkItem a partir des params du request
    workitem = parse_workitem
    puts "workitems_controller.update:workitem="+workitem.inspect
    workitem_ident = "#{in_flow_workitem.fei.wfid}/#{OpenWFE.to_uscores(in_flow_workitem.fei.expid)}"
    if store_name = params[:store_name]
      ar_workitem.store_name = store_name
      ar_workitem.save!
      flash[:notice] = "workitem #{workitem_ident} delegated to store '#{store_name}'"
      history_log(
      'delegated',
      :fei => in_flow_workitem.fei, :message => "wi delegated to '#{store_name}'")
    elsif params[:state] == 'proceeded'
      puts "workitems_controller.update:wfid="+params[:wfid]
      in_flow_workitem.attributes = workitem.attributes
      puts "workitems_controller.update:in_flow_workitem proceeded********="+in_flow_workitem.inspect
      RuotePlugin.ruote_engine.reply(in_flow_workitem)
      flash[:notice] = "workitem #{workitem_ident} proceeded"
      # sauve history
      process = ruote_engine.process_status(params[:wfid])
      unless process.nil?
        tree=process.current_tree
      else
        tree=nil
      end
      history_created=history_log('proceeded', :fei => in_flow_workitem.fei, :tree=>tree.to_json )
      wi_links_update(ar_workitem, params[:wfid])
    else
      puts "workitems_controller.update:att="+workitem.attributes.inspect
      ar_workitem.replace_fields(workitem.attributes)
      flash[:notice] = "workitem #{workitem_ident} modified"
      history_log('saved', :fei => in_flow_workitem.fei, :message => 'wi saved')
    end
    #puts "workitems_controller.update:fin"
    redirect_to :action => 'index'
    #
    # TODO : no need for a redirection in case of xml/json...
  end

  protected

  #
  # find workitem, says 'unauthorized' if the user is attempting to
  # see / update an off-limit workitem
  #
  def find_ar_workitem
    workitem = OpenWFE::Extras::ArWorkitem.find_by_wfid_and_expid(
    params[:wfid], OpenWFE.to_dots(params[:expid]))
    ret=@current_user.may_see?(workitem) ? workitem : nil
    #puts "workitems_controller.find_workitem:"+ret.inspect
    get_wi_links(workitem) unless workitem.nil?
    ret
  end

  def get_wi_links(workitem)
    @wi_links=[]
    unless workitem.nil?
      Link.find_childs("workitem",workitem,"document").each do |link|
        @wi_links<<{:object=>Document.find(link.child_id), :link=>link}
      end
      Link.find_childs("workitem",workitem,"part").each do |link|
        @wi_links<<{:object=>Part.find(link.child_id), :link=>link}
      end
      Link.find_childs("workitem",workitem,"product").each do |link|
        @wi_links<<{:object=>Product.find(link.child_id), :link=>link}
      end
      Link.find_childs("workitem",workitem,"customer").each do |link|
        @wi_links<<{:object=>Customer.find(link.child_id), :link=>link}
      end
      #puts "workitems_controller.get_wi_links="+workitem.id.to_s+":"+@links.inspect
    end
  end

  def wi_links_update(cur_wi, wfid)
    sleep 1.0
    OpenWFE::Extras::ArWorkitem.destroy(cur_wi.id)
    new_wi = OpenWFE::Extras::ArWorkitem.find_by_wfid(wfid)
    #    puts "workitems_controller.wi_links_update:cur_wi="+cur_wi.id.to_s+":"+cur_wi.wfid.to_s+":"+cur_wi.expid.to_s
    unless new_wi.nil?
      # deroulement  du workflow, on relie les objets avec la tache en cours du workflow
      Link.find_childs("workitem",cur_wi,"document").each do |link|
        link.father_id=new_wi.id
        link.save
      end
      Link.find_childs("workitem",cur_wi,"part").each do |link|
        link.father_id=new_wi.id
        link.save
      end
    else
      # fin du workflow, on relie les objets avec l' history du workflow
      opts={}
      opts[:page]=nil
      opts[:conditions]="wfid = '"+wfid+"' and event = 'proceeded'" #TODO
      #puts "processes_controller.tree:opts="+opts.inspect
      history = OpenWFE::Extras::HistoryEntry.paginate(opts).last
      #puts "workitems_controller.wi_links_update:history="+history.inspect
      Link.find_childs("workitem",cur_wi,"document").each do |link|
        link.father_object="history"
        link.father_id=history.id
        link.save
      end
      Link.find_childs("workitem",cur_wi,"part").each do |link|
        link.father_object="history"
        link.father_id=history.id
        link.save
      end
    end
  end

  #
  # parsing incoming workitems
  #
  def parse_workitem

    begin

      ct = request.content_type.to_s
      # TODO : deal with Atom[Pub]
      return OpenWFE::Xml::workitem_from_xml(request.body.read) \
      if ct.match(/xml$/)
      return OpenWFE::Json.workitem_from_json(request.body.read) \
      if ct.match(/json$/)
      #
      # then we have a form...
      #if definition_id = params[:definition_id]
      #  definition = Definition.find(definition_id)
      #  params[:definition_url] = definition.local_uri if definition
      #end
      #if attributes = params[:attributes]
      #  params[:attributes] = ActiveSupport::JSON::decode(attributes)
      #end
      wi = OpenWFE::WorkItem.from_h(params)
      wi.attributes = ActiveSupport::JSON.decode(wi.attributes) \
      if wi.attributes.is_a?(String)
      wi
    rescue Exception => e
      logger.warn("failed to parse workitem : #{e}")
      nil
    end
  end

end

