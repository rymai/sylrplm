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
# 
#  processes_controller.rb
#  sylrplm
#  
#  Created by Sylvère on 2012-02-04.
#  Copyright 2012 Sylvère. All rights reserved.
# 

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
    return error_reply('you are not allowed to launch this process', 403) unless @current_user.may_launch?(@definition)
  end

  # POST /processes
  #
  def create
    name="process_controllers."+__method__.to_s+":"
    LOG.info {params.inspect}
    @definition = Definition.find(params[:definition_id])
    li = parse_launchitem
    options = { :variables => { 'launcher' => @current_user.login } }
    begin
      fei = RuotePlugin.ruote_engine.launch(li, options)
      puts name+" fei("+fei.wfid+") launched"
      headers['Location'] = process_url(fei.wfid)
      nb=0
      workitem = nil
      while nb<5 and workitem.nil?
        puts name+" boucle "+nb.to_s+":"+fei.wfid
        sleep 1.0
        nb+=1
        workitem = OpenWFE::Extras::ArWorkitem.find_by_wfid(fei.wfid)
      end
      respond_to do |format|
        unless workitem.nil?
          flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_process), :ident => "#{workitem.id} #{fei.wfid}")    
          format.html {
            redirect_to :action => 'show', :id => fei.wfid }
          format.json {
            render :json => "{\"wfid\":#{fei.wfid}}", :status => 201 }
          format.xml {
            render :xml => "<wfid>#{fei.wfid}</wfid>", :status => 201 }
        else
          flash[:notice] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process), :msg => "workitem non trouve")    
          format.html { redirect_to new_process_path(:definition_id => @definition.id)}
          format.xml  { render :xml => fei.errors, :status => :unprocessable_entity }
        end
      end
    rescue Exception => e
      LOG.error { "fei not launched error="+e.inspect}
      LOG.error {" fei not launched li="+li.inspect}
      LOG.error {" options="+options.inspect}
      e.backtrace.each {|x| LOG.error {x}}
      respond_to do |format|
        flash[:notice] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process), :msg => nil)
          format.html { redirect_to new_process_path(:definition_id => @definition.id)}
          format.xml  { render :xml => e, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /processes/:id
  #
  def destroy
    #    puts "processes_controller.destroy:params="+params.inspect
    begin
      @process = ruote_engine.process_status(params[:id])
      ::Ruote::Sylrplm::ArWorkitem.destroy_process(@process.wfid)
      RuotePlugin.ruote_engine.cancel_process(params[:id])
      sleep 0.200
      redirect_to :controller => :processes, :action => :index
    rescue Exception => e
      LOG.error " pb destroy "+params[:id]
      e.backtrace.each {|x| LOG.error x}
      respond_to do |format|
            flash[:notice] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_process), :ident => params[:id])
            format.html { redirect_to processes_path}
      end
    end
  end

  # GET /processes/:id/tree
  #
  def tree
    name=__FILE__+"."+__method__.to_s+":"
    #puts name+" params="+params.inspect
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
      #puts name+" opts="+opts.inspect
      history = Ruote::Sylrplm::HistoryEntry.paginate(opts)
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
    name=__FILE__+"."+__method__.to_s+":"
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

