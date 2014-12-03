#
#  processes_controller.rb
#  sylrplm
#
#  Created by Sylvère on 2012-02-04.
#  Copyright 2012 Sylvère. All rights reserved.
#

require 'openwfe/representations'
require 'ruote/sylrplm/workitems'

class ProcessesController < ApplicationController
  ###before_filter :login_required
  # GET /processes
  #
  def index
    all_processes=Ruote::Sylrplm::Process.get_all

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
	show_
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
    fname= "#{controller_class_name}.#{__method__}"
		#LOG.debug (fname){"begin:params=#{params}"}
    @definition = Definition.find(params[:definition_id])
		respond_to do |format|
			if current_user.may_launch?(@definition)
				flash[:notice] = t(:user_allowed_to_launch_process, :login => current_user.login, :definition => @definition.description)
				format.html
			else
				flash[:warn] = t(:user_not_allowed_to_launch_process, :login => current_user.login, :definition => @definition.description)
				format.html { redirect_to(:controller=> "definitions", :action=> "new_process")}
			end
		end
  end

  # POST /processes
  #
  def create
    fname="process_controllers."+__method__.to_s+":"
    @definition = Definition.find(params[:definition_id])
    li = parse_launchitem
    options = { :variables => { 'launcher' => @current_user.login } }
    begin
      fei = RuotePlugin.ruote_engine.launch(li, options)
      puts fname+" fei("+fei.wfid+") launched options="+options.to_s
      headers['Location'] = process_url(fei.wfid)
      nb=0
      workitem = nil
      while nb<5 and workitem.nil?
        puts fname+" boucle "+nb.to_s+":"+fei.wfid
        sleep 0.3
        nb+=1
        workitem = ::Ruote::Sylrplm::ArWorkitem.get_workitem(fei.wfid)
      end
      #puts fname+" workitem="+workitem.inspect
      respond_to do |format|
        unless workitem.nil?
          flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_process), :ident => "#{workitem.id} #{fei.wfid}")
          	params[:id]=fei.wfid
				show_
				format.html { render :action => "show" }
          format.json {
            render :json => "{\"wfid\":#{fei.wfid}}", :status => 201 }
          format.xml {
            render :xml => "<wfid>#{fei.wfid}</wfid>", :status => 201 }
        else
          flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process), :msg => "workitem non trouve")
          format.html { redirect_to "/main" }
          ##format.html { redirect_to new_process_path(:definition_id => @definition.id)}
          format.xml  { render :xml => fei.errors, :status => :unprocessable_entity }
        end
      end
    rescue Exception => e
      LOG.error { "fei not launched error="+e.inspect}
      LOG.error {" fei not launched li="+li.inspect}
      LOG.error {" options="+options.inspect}
      e.backtrace.each {|x| LOG.error {x}}
      respond_to do |format|
        flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process), :msg => "fei not launched error=#{e}")
          #format.html { redirect_to new_process_path(:definition_id => @definition.id)}
          format.html { redirect_to ({:controller => :definitions , :action => :new_process}) }
          format.xml  { render :xml => e, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /processes/:id
  #
  def destroy
    fname="process_controllers.#{__method__}"
    begin
      @process = ruote_engine.process_status(params[:id])
      ruote_engine.cancel_process(params[:id])
      ::Ruote::Sylrplm::ArWorkitem.destroy_process(@process.wfid)
      sleep 0.200
      redirect_to :controller => :processes, :action => :index
    rescue Exception => e
      LOG.error (fname) {" pb destroy #{params[:id]}, e=#{e}"}
      e.backtrace.each {|x| LOG.error x}
      respond_to do |format|
            flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_process), :ident => params[:id])
            format.html { redirect_to processes_path}
      end
    end
  end

  # GET /processes/:id/tree
  #
  def tree
   	fname= "#{controller_class_name}.#{__method__}"
		#LOG.debug (fname){"begin:params=#{params}"}
    process = ruote_engine.process_status(params[:id])
    var = params[:var] || 'proc_tree'
    unless process.nil?
      # TODO : use Rails callback
      render_text="var #{var} = #{process.current_tree.to_json};"
    else
      opts={}
      opts[:page]=nil
      opts[:conditions]="wfid = '"+params[:id]+"' and event = 'proceeded'" #TODO
      #puts fname+" opts="+opts.inspect
      history = Ruote::Sylrplm::HistoryEntry.paginate(opts)
      render_text = "var #{var} = #{history.last.tree};"
    end
    #LOG.info (fname){"render_text=#{render_text}"}
    render(
      :text => render_text,
      :content_type => 'text/javascript')
  end

  #
  ###############################################################################
  #
  private
def show_
	@process = ruote_engine.process_status(params[:id])
end
  def parse_launchitem_mis_dans_lib
    fname=__FILE__+"."+__method__.to_s+":"
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
    ret=OpenWFE::LaunchItem.from_h(params)
    ret
  end


end

