#
#  processes_controller.rb
#  sylrplm
#
#  Created by Sylvère on 2012-02-04.
#  Copyright 2012 Sylvère. All rights reserved.
#
class ProcessesController < ApplicationController
	# GET /processes
	#
	def index
		fname= "#{self.class.name}.#{__method__}"
		@processes = RuoteKit.engine.processes
		#LOG.debug(fname){"@processes=#{@processes.size}:#{@processes}"}
		LOG.debug(fname){"#{@processes.size} processes"}
		respond_to do |format|
			format.html
			format.json do
				render(:json => OpenWFE::Json.processes_to_h(
        @processes ,
        :linkgen => LinkGenerator.new(request)).to_json)
			end
			format.xml do
				render(
        :xml => OpenWFE::Xml.processes_to_xml(
        @processes ,
        :linkgen => LinkGenerator.new(request), :indent => 2))
			end
		end
	end

	# GET /processes/1
	#
	def show
		fname= "#{self.class.name}.#{__method__}"
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
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"begin:params=#{params}"}
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
		fname= "#{self.class.name}.#{__method__}"
		@definition = Definition.find(params[:definition_id])
		variables = { :launcher => @current_user.login }
		options = { :fields=>@definition.launch_fields}
		begin
			definition_uri=@definition.uri
			LOG.debug(fname) {" definition_uri=#{definition_uri}"}
			#appelle /usr/lib64/ruby/gems/2.1.0/gems/ruote-2.3.0.3/lib/ruote/receiver/base.rb
			fei_wfid = RuoteKit.engine.launch(definition_uri)
			LOG.debug(fname) {" process lance: fei_wfid(#{fei_wfid}) launched options=#{options}"}
			# blocks until the process terminates or gets into an error
			flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_process), :ident => "#{fei_wfid}")
			params[:id]=fei_wfid
			sleep(1.0)
			show_
			respond_to do |format|
				format.html { render :action => "show" }
				format.json {
					render :json => "{\"wfid\":#{fei_wfid}}", :status => 201 }
				format.xml {
					render :xml => "<wfid>#{fei_wfid}</wfid>", :status => 201 }
			end
		rescue Exception => e
			LOG.error(fname) { "fei not launched error="+e.inspect}
			LOG.error(fname) {" options=#{options}"}
			e.backtrace.each {|x| LOG.error {x}}
			respond_to do |format|
				flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process), :msg => "fei not launched error=#{e}")
				LOG.debug(fname) {" flash[:error]#{flash[:error]} redirect_to  definitions/new_process"}
				format.html { render :action => :new}
				format.xml  { render :xml => e, :status => :unprocessable_entity }
			end
		end
	end

	# POST /processes
	#
	def create_old
		fname= "#{self.class.name}.#{__method__}"
		@definition = Definition.find(params[:definition_id])
		variables = { :launcher => @current_user.login }
		options = { :fields=>@definition.launch_fields}
		begin
			definition_uri=@definition.uri
			LOG.debug(fname) {" definition_uri=#{definition_uri}"}
			#appelle /usr/lib64/ruby/gems/2.1.0/gems/ruote-2.3.0.3/lib/ruote/receiver/base.rb
			fei_wfid = RuoteKit.engine.launch(definition_uri)
			LOG.debug(fname) {" process lance: fei_wfid(#{fei_wfid}) launched options=#{options}"}
			# blocks until the process terminates or gets into an error
			loop=0
			proc=nil
			while(loop<10 && proc==nil)
				proc=::RuoteKit.engine.process(fei_wfid)
				sleep(0.2)
				loop+=1
			#LOG.debug(fname) {"process=#{proc}"}
			end
			unless proc.nil?
				err = proc.errors
				LOG.debug(fname) {"intercepted an error ??? : #{proc.errors}"} unless proc.errors.nil?
				#
				respond_to do |format|
					workitems = proc.workitems
					LOG.debug(fname) {"workitems still open : #{workitems.size}"}
					workitem=nil
					workitems.each do |wi|
						LOG.debug(fname) {"wi.fei.wfid=#{wi.fei.wfid} fei_wfid=#{fei_wfid}"}
						if wi.fei.wfid==fei_wfid
						workitem=wi
						break
						end
					end
					LOG.debug(fname) {"workitem=#{workitem.inspect} "}
					unless  workitem.nil?
						flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_process), :ident => "#{workitem} #{fei_wfid}")
						params[:id]=fei_wfid
						show_
						format.html { render :action => "show" }
						format.json {
							render :json => "{\"wfid\":#{fei_wfid}}", :status => 201 }
						format.xml {
							render :xml => "<wfid>#{fei_wfid}</wfid>", :status => 201 }
					else
						flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process), :msg => "workitem for wfid #{fei_wfid} non trouve")
						format.html { render :action => "new" , :definition_id => params[:definition_id]}
						format.xml  { render :xml => fei.errors, :status => :unprocessable_entity }
					end
					LOG.debug(fname) {" flash=#{flash}"}
				end
			else
				respond_to do |format|
					flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process), :msg => "process for wfid #{fei_wfid} not found")
					format.html { render :action => "new" , :definition_id => params[:definition_id]}
					format.xml  { render :xml => fei.errors, :status => :unprocessable_entity }
				end
			end
		rescue Exception => e
			LOG.error(fname) { "fei not launched error="+e.inspect}
			LOG.error(fname) {" options=#{options}"}
			e.backtrace.each {|x| LOG.error {x}}
			respond_to do |format|
				flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process), :msg => "fei not launched error=#{e}")
				LOG.debug(fname) {" flash[:error]#{flash[:error]} redirect_to  definitions/new_process"}
				format.html { render :action => :new}
				format.xml  { render :xml => e, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /processes/:id
	#
	def destroy
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"begin:params=#{params}"}
		begin
			@process = RuoteKit.engine.process(params[:id])
			RuoteKit.engine.remove_process(params[:id])
			redirect_to :action => :index
		rescue Exception => e
			LOG.error(fname) {" pb destroy #{params[:id]}, e=#{e}"}
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
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"begin:params=#{params}"}
		process = RuoteKit.engine.process(params[:id])
		var = params[:var] || 'proc_tree'
		unless process.nil?
			# TODO : use Rails callback
			render_text="var #{var} = #{process.current_tree.to_json};"
		else
			opts={}
			opts[:page]=nil
			opts[:conditions]="wfid = '"+params[:id]+"' and event = 'proceeded'" #TODO
		end
		LOG.info(fname){"render_text=#{render_text}"}
		render(
	      :text => render_text,
	      :content_type => 'text/javascript')
	end

	#
	###############################################################################
	#
	private

	def show_
		fname= "#{self.class.name}.#{__method__}"
		@process = RuoteKit.engine.process(params[:id])
		LOG.debug(fname){"params[:id]=#{params[:id]} process=#{@process}"}
	end

end

