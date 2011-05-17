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

#require 'ruote/sylrplm'

class ProcessesController < ApplicationController
  ###before_filter :login_required
  # GET /processes
  #
  def index
    #    puts "processes_controller.index:params="+params.inspect
    v=ruote_engine.process_statuses.values

    vv=[]
    v.each do  |ps|
      #      puts "ProcessesController.index:ps("+v.size.to_s+")="+ps.launch_time.inspect
      unless ps.launch_time.nil?
        vv<<ps
      end
    end
    all_processes = vv.sort_by { |ps|
      ps.launch_time
    }.reverse

    #all_processes = v

    if wf = params[:workflow]
      all_processes = all_processes.select { |ps| ps.wfname == wf }
    end
    if l = params[:launcher]
      all_processes = all_processes.select { |ps| ps.launcher == l }
    end

    @processes = all_processes.paginate(:page => params[:page])

    respond_to do |format|

      format.html # => app/views/processes/index.html.erb

      format.json do
        render(:json => OpenWFE::Json.processes_to_h(
        params[:page] ? @processes : all_processes,
        :linkgen => LinkGenerator.new(request)).to_json)
      end

      format.xml do
        render(
        :xml => OpenWFE::Xml.processes_to_xml(
        params[:page] ? @processes : all_processes,
        :linkgen => LinkGenerator.new(request), :indent => 2))
      end
    end
  end

  # GET /processes/1
  #
  def show
    #    puts "processes_controller.show:"
    @process = ruote_engine.process_status(params[:id])

    respond_to do |format|

      if @process
        format.html # => app/views/show.html.erb

        format.json do
          render(:json => OpenWFE::Json.process_to_h(
          @process, :linkgen => LinkGenerator.new(request)).to_json)
        end

        format.xml do
          render(
          :xml => OpenWFE::Xml.process_to_xml(
          @process, :linkgen => LinkGenerator.new(request), :indent => 2))
        end
      else

        flash[:error] = "process launch failed"

        format.html do
          redirect_to :action => 'index'
        end
        format.json { render(:text => flash[:error], :status => 404) }
        format.xml { render(:text => flash[:error], :status => 404) }
      end
    end
  end

  # GET /processes/new
  #
  def new
    #    puts "processes_controller.new:params="+params.inspect
    @definition = Definition.find(params[:definition_id])

    @relation_types_document = Typesobject.get_types_names(:relation_document)
    @relation_types_part     = Typesobject.get_types_names(:relation_part)
    @relation_types_project  = Typesobject.get_types_names(:relation_project)
    @relation_types_customer  = Typesobject.get_types_names(:relation_customer)

    return error_reply('you are not allowed to launch this process', 403) unless @current_user.may_launch?(@definition)

    @payload_partial = determine_payload_partial(@definition)

  end

  # POST /processes
  #
  def create
    #    puts "processes_controller.create:params="+params.inspect
    @definition = Definition.find(params[:definition_id])
    li = parse_launchitem

    options = { :variables => { 'launcher' => @current_user.login } }

    fei = RuotePlugin.ruote_engine.launch(li, options)

    #    puts "processes_controller.create:fei("+fei.wfid+")"

    sleep 1.0

    headers['Location'] = process_url(fei.wfid)
    workitem = OpenWFE::Extras::ArWorkitem.find_by_wfid(fei.wfid)
    #puts "processes_controller.create:workitem from fei("+fei.wfid+")="+workitem.inspect
    respond_to do |format|
      unless workitem.nil?

        #flash[:notice] = "<br/>launched process instance #{workitem.id} #{fei.wfid}"
        flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_process), :ident => "#{workitem.id} #{fei.wfid}")    

        nb=add_objects(workitem, @favori.get("document"), "document")
        nb+=add_objects(workitem, @favori.get("part"), "part")
        nb+=add_objects(workitem, @favori.get("project"), "project")
        nb+=add_objects(workitem, @favori.get("customer"), "customer")
        if(nb>0)
          workitem.save
        end

        format.html {
          redirect_to :action => 'show', :id => fei.wfid }
        format.json {
          render :json => "{\"wfid\":#{fei.wfid}}", :status => 201 }
        format.xml {
          render :xml => "<wfid>#{fei.wfid}</wfid>", :status => 201 }

      else
        flash[:notice] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process))    
        format.html { redirect_to new_process_path(:definition_id => @definition.id)}
        format.xml  { render :xml => fei.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /processes/:id
  #
  def destroy
    #    puts "processes_controller.destroy:params="+params.inspect
    RuotePlugin.ruote_engine.cancel_process(params[:id])

    sleep 0.200

    redirect_to :controller => :processes, :action => :index
  end

  # GET /processes/:id/tree
  #
  def tree
    #    puts "processes_controller.tree:params="+params.inspect
    process = ruote_engine.process_status(params[:id])
    var = params[:var] || 'proc_tree'
    unless process.nil?
      # TODO : use Rails callback
      render(
      :text => "var #{var} = #{process.current_tree.to_json};",
      :content_type => 'text/javascript')
    else
      opts={}
      opts[:page]=nil
      opts[:conditions]="wfid = '"+params[:id]+"' and event = 'proceeded'" #TODO
      puts "processes_controller.tree:opts="+opts.inspect
      history = OpenWFE::Extras::HistoryEntry.paginate(opts)
      render(
      :text => "var #{var} = #{history.last.tree};",
      :content_type => 'text/javascript')
    end
  end

  #
  ###############################################################################
  #
  private

  def parse_launchitem

    ct = request.content_type.to_s

    # TODO : deal with Atom[Pub]
    # TODO : sec checks !!!

    begin

      return OpenWFE::Xml::launchitem_from_xml(request.body.read) \
      if ct.match(/xml$/)

      return OpenWFE::Json.launchitem_from_h(request.body.read) \
      if ct.match(/json$/)

    rescue Exception => e

      raise ErrorReply.new(
      'failed to parse launchitem from request body', 400)
    end

    #
    # then we have a form...

    if definition_id = params[:definition_id]

      # is the user allowed to launch that process [definition] ?

      definition = Definition.find(definition_id)

      raise ErrorReply.new(
      'you are not allowed to launch this process', 403
      ) unless @current_user.may_launch?(definition)

      params[:definition_url] = definition.local_uri if definition

    elsif definition_url = params[:definition_url]

      raise ErrorReply.new(
      'not allowed to launch process definitions from adhoc URIs', 400
      ) unless @current_user.may_launch_from_adhoc_uri?

    elsif definition = params[:definition]

      # is the user allowed to launch embedded process definitions ?

      raise ErrorReply.new(
      'not allowed to launch embedded process definitions', 400
      ) unless @current_user.may_launch_embedded_process?

    else

      raise ErrorReply.new(
      'failed to parse launchitem from request parameters', 400)
    end

    if fields = params[:fields]
      params[:fields] = ActiveSupport::JSON::decode(fields)
    end

    puts "processes_controller.parse_launchitem:"+params.inspect
    ret=OpenWFE::LaunchItem.from_h(params)
    ret
  end

  def add_objects(workitem, favori, type_object)
    fields = workitem.field_hash
    msg=""
    ret=0
    unless favori.nil? || params[:relation].nil? || params[:relation][type_object].nil?
      relation=params[:relation][type_object]
      #      puts "processes_controller.add_objects:workitem="+workitem.id.to_s+" rel="+relation.inspect+" favori="+favori.inspect
      favori.each do |item|
        url="/"+type_object+"s/"+item.id.to_s
        label=type_object+":"+item.ident+"-"+relation
        fields[:params][url]=label
        msg += "\nField added:"+label
        ret+=1
      end
      #reset_favori_document
    else
      msg += "\nNothing to add:"+type_object
    end
    workitem.replace_fields(fields)
    puts  "processes_controller.add_objects:"+workitem.field_hash.inspect
    puts  "processes_controller.add_objects:"+type_object+"="+ret.to_s+":"+msg
    ret
  end

  def add_objects_old(workitem, favori, type_object)
    unless favori.nil? || params[:relation].nil? || params[:relation][type_object].nil?
      relation=params[:relation][:document]
      ret=""
      #      puts "processes_controller.add_objects:workitem="+workitem.id.to_s+" rel="+relation.inspect+" favori="+favori.inspect
      params.each do |item|
      end
      favori.items.each do |item|
        link_=Link.create_new_byid("workitem", workitem.id, type_object, item.id, relation)
        link=link_[:link]
        if(link!=nil)
          if(link.save)
            ret += t(:ctrl_object_added, :typeobj =>t("ctrl_"+type_object), :ident=>item.ident, :relation=>relation,:msg=>t(link_[:msg]))
          else
            ret += t(:ctrl_object_not_added, :typeobj =>t("ctrl_"+type_object), :ident=>item.ident, :relation=>relation,:msg=>t(link_[:msg]))
          end
        else
          ret += t(:ctrl_object_not_linked, :typeobj =>t("ctrl_"+type_object), :ident=>item.ident, :relation=>relation, :msg=>nil)
        end
      end
      #reset_favori_document
    else
      ret = t(:ctrl_nothing_to_paste,:typeobj =>t("ctrl_"+type_object))
    end
    ret
  end

end

