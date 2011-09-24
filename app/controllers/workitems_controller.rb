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
require 'ruote/sylrplm/workitems'



class WorkitemsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  before_filter :authorize, :except => nil
  access_control(Access.find_for_controller(controller_class_name))
  # GET /workitems
  #  or
  # GET /workitems?q=:q || GET /workitems?query=:q
  #  or
  # GET /workitems?p=:p || GET /workitems?participant=:p
  #
  def index
    #puts "workitems_controller.index:params="+params.inspect
    @workitems=[]
    unless @current_user.nil?
      @query = params[:q] || params[:query]
      #puts "workitems_controller.index:store_names="+@current_user.store_names.inspect
      if @query
        @workitems = Ruote::Sylrplm::ArWorkitem.search(@query, @current_user.is_admin? ? nil : @current_user.store_names)
      #TODO syl @current_user.is_admin? ? nil : @current_user.store_names)
      #TODO : paginate that !
      else
        opts = { :order => 'dispatch_time DESC' }
        opts[:conditions] = { :store_name => @current_user.store_names }
        opts[:page] = (params[:page].nil? ? SYLRPLM::NB_ITEMS_PER_PAGE :  params[:page])
        #      puts "workitems_controller.index:page="+opts[:page].inspect
        @workitems = Ruote::Sylrplm::ArWorkitem.paginate_by_params(
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
    end
    @workitems.each do |en|
      en.link_attributes={"relation"=>""}
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
    @wi_links = get_wi_links(@workitem)
    nb=add_objects(@workitem, @favori.get("document"), "document")
    nb+=add_objects(@workitem, @favori.get("part"), "part")
    nb+=add_objects(@workitem, @favori.get("project"), "project")
    nb+=add_objects(@workitem, @favori.get("customer"), "customer")
    nb+=add_objects(@workitem, @favori.get("user"), "user")
    if nb>0
    @workitem.save
    end
    return error_reply('no workitem', 404) unless @workitem

  # only responds in HTML...
  end

  # GET /workitems/:wfid/:expid
  #
  def show
    #    puts "workitems_controller.show:params="+params.inspect
    @workitem = find_ar_workitem
    @wi_links = get_wi_links(@workitem)

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
    name=__FILE__+"."+__method__.to_s+":"
    #puts "workitems_controller.update:params="+params.inspect
    # select du ArWorkitem
    ar_workitem = find_ar_workitem
    return error_reply('no workitem', 404) unless ar_workitem
    #puts "workitems_controller.update:ar_workitem="+ar_workitem.inspect
    # creation du InFlowWorkItem depuis le ar_workitem
    in_flow_workitem = ar_workitem.to_owfe_workitem
    #puts "workitems_controller.update:in_flow_workitem="+in_flow_workitem.inspect
    # get WorkItem a partir des params du request
    workitem = parse_workitem
    #puts "workitems_controller.update:workitem="+workitem.inspect
    workitem_ident = "#{in_flow_workitem.fei.wfid}/#{OpenWFE.to_uscores(in_flow_workitem.fei.expid)}"
    if store_name = params[:store_name]
      puts "workitems_controller.update:store="+store_name
      ar_workitem.store_name = store_name
      ar_workitem.save!
      flash[:notice] = t(:ctrl_workitem_delegated, :ident => workitem_ident, :store => store_name)
      history_log(
      'delegated',
      :fei => in_flow_workitem.fei, :message => "wi delegated to '#{store_name}'")
    elsif params[:state] == 'proceeded'
      puts "workitems_controller.update:proceeded:wfid="+params[:wfid]
      in_flow_workitem.attributes = workitem.attributes
      #puts "workitems_controller.update:in_flow_workitem proceeded********="+in_flow_workitem.inspect
      begin
        RuotePlugin.ruote_engine.reply(in_flow_workitem)
        flash[:notice] = t(:ctrl_workitem_proceeded, :ident => workitem_ident)
        # sauve history
        process = ruote_engine.process_status(params[:wfid])
        unless process.nil?
        tree=process.current_tree
        else
          tree=nil
        end
        history_created=history_log('proceeded', :fei => in_flow_workitem.fei, :tree=>tree.to_json )
        wi_links_update(ar_workitem, params[:wfid])
      rescue Exception => e
        LOG.error name+in_flow_workitem.inspect
        LOG.error " error="+e.inspect
        e.backtrace.each {|x| LOG.error x}
        puts name+in_flow_workitem.inspect
        puts " error="+e.inspect
        e.backtrace.each {|x| puts x}
        respond_to do |format|
          flash[:notice] = t(:ctrl_workitem_not_updated, :ident => workitem_ident+":"+e.inspect)
          format.html { redirect_to edit_workitem_url(workitem) }
          format.xml  { render :xml => e, :status => :unprocessable_entity }
        end
      return
      end
    else
      puts "workitems_controller.update:att="+workitem.attributes.inspect
      ar_workitem.replace_fields(workitem.attributes)
      flash[:notice] = t(:ctrl_workitem_updated, :ident => workitem_ident)
      history_log('saved', :fei => in_flow_workitem.fei, :message => 'wi saved')
    end
    #puts "workitems_controller.update:fin"
    redirect_to :action => 'index'
  #
  # TODO : no need for a redirection in case of xml/json...

  end

  private

  #
  # find workitem, says 'unauthorized' if the user is attempting to
  # see / update an off-limit workitem
  #
  def find_ar_workitem
    workitem = Ruote::Sylrplm::ArWorkitem.find_by_wfid_and_expid(
    params[:wfid], OpenWFE.to_dots(params[:expid]))
    ret=@current_user.may_see?(workitem) ? workitem : nil
    #puts "workitems_controller.find_workitem:"+ret.inspect
    ret
  end

  def add_objects(workitem, favori, type_object)
    msg=""
    ret=0
    unless favori.nil?
      fields = workitem.field_hash
      if fields == nil
        fields = {}
        fields["params"] = {}
      end
      #puts "workitems_controller.add_objects:workitem="+workitem.id.to_s
      #puts "workitems_controller.add_objects:favori="+favori.inspect
      #puts "workitems_controller.add_objects:fields="+fields.inspect
      favori.each do |item|
        url="/"+type_object+"s" #bidouille
        url+="/"+item.id.to_s
        label=type_object+":"+item.ident
        puts "workitems_controller.add_objects:url="+url+" label="+label+ " fields="+fields["params"].inspect
        fields["params"][url]=label
        msg += "\nField added:"+label
        ret+=1
      end
      workitem.replace_fields(fields)
      empty_favori_by_type(type_object)
    else
      msg += "\nNothing to add:"+type_object
    end
    #puts  "workitems_controller.add_objects:"+workitem.field_hash.inspect
    #puts  "workitems_controller.add_objects:"+type_object+"="+ret.to_s+":"+msg
    ret
  end

  def get_wi_links(workitem)
    ret=[]
    unless workitem.nil?
      Link.find_childs(workitem,"document").each do |link|
        ret<<{:typeobj =>Document.find(link.child_id), :link=>link}
      end
      Link.find_childs(workitem,"part").each do |link|
        ret<<{:typeobj =>Part.find(link.child_id), :link=>link}
      end
      Link.find_childs(workitem,"project").each do |link|
        ret<<{:typeobj =>Product.find(link.child_id), :link=>link}
      end
      Link.find_childs(workitem,"customer").each do |link|
        ret<<{:typeobj =>Customer.find(link.child_id), :link=>link}
      end
      Link.find_childs(workitem,"user").each do |link|
        ret<<{:typeobj =>User.find(link.child_id), :link=>link}
      end
    #puts "workitems_controller.get_wi_links="+ret.size.to_s+":"+workitem.id.to_s+":"+ret.inspect
    end
    ret
  end

  def wi_links_update(cur_wi, wfid)
    sleep 3.0
    Ruote::Sylrplm::ArWorkitem.destroy(cur_wi.id)
    puts "workitems_controller.wi_links_update:cur_wi="+cur_wi.id.to_s+":"+cur_wi.wfid.to_s+":"+cur_wi.expid.to_s
    news_wi_ = Ruote::Sylrplm::ArWorkitem.find_by_wfid_(wfid)
    #puts "workitems_controller.wi_links_update:news_wi_="+news_wi_.inspect
    if news_wi_.count != 0
      if news_wi_.is_a?(Array)
        news_wi = news_wi_
      else
        news_wi = [news_wi_]
      end
      # deroulement  du workflow, on relie les objets avec la tache en cours du workflow
      wi_link_replace("document", cur_wi, news_wi)
      wi_link_replace("part", cur_wi, news_wi)
      wi_link_replace("project", cur_wi, news_wi)
      wi_link_replace("customer", cur_wi, news_wi)
      wi_link_replace("user", cur_wi, news_wi)
    else
      # fin du workflow, on relie les objets avec l' history du workflow
      opts={}
      opts[:page]=nil
      opts[:conditions]="wfid = '"+wfid+"' and event = 'proceeded'" #TODO
      #puts "workitems_controller.wi_links_update:opts="+opts.inspect
      history = Ruote::Sylrplm::HistoryEntry.paginate(opts).last
      #puts "workitems_controller.wi_links_update:history="+history.inspect
      wi_link_history("document", cur_wi, history)
      wi_link_history("part", cur_wi, history)
      wi_link_history("project", cur_wi, history)
      wi_link_history("customer", cur_wi, history)
      wi_link_history("user", cur_wi, history)
    end
  end

  def wi_link_replace(type, cur_wi, news_wi)
    links=Link.find_childs(cur_wi, type)
    puts "workitems_controller.wi_link_replace:"+type+" "+links.count.to_s+" links"
    if links.count >= 1
      link = links[0]
    end
    #puts "workitems_controller.wi_link_replace:link="+link.inspect
    unless link.nil?
      news_wi.each_with_index do |new_wi, idx|
        #puts "workitems_controller.wi_links_update:new_wi("+idx.to_s+"/"+news_wi.count.to_s+" )="+new_wi.id.to_s+":"+new_wi.wfid.to_s+":"+new_wi.expid.to_s
        new_link=link.clone
        new_link.father_id = new_wi.id
        new_link.save
      end
      link.delete
    end
  end

  def wi_link_history(type, cur_wi, history)
    Link.find_childs( cur_wi, type).each do |link|
      #puts "workitems_controller.wi_link_history"+link.inspect
      link.father_plmtype = history.model_name
      link.father_id = history.id
      link.save
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
      LOG.warn("failed to parse workitem : #{e}")
      nil
    end
  end

end

