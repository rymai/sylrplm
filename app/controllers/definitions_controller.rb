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
class DefinitionsController < ApplicationController
	# GET /definitions
	# GET /definitions.xml
	#
	before_filter :authorize, :except => nil
	access_control(Access.find_for_controller(controller_name.classify))
	#
	def index
		index_
		unless @definitions.length==0
			respond_to do |format|
				format.html # index.html.erb
				format.xml { render :xml => @definitions.to_xml(:request => request) }
				format.json { render :json => @definitions.to_json(:request => request) }
			end
		end
	end

	def index_
		@definitions = Definition.find_all_for(@current_user)
	end

	def index_execute
		ctrl_index_execute
	end

	def new_process
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"begin:params=#{params}"}
		LOG.debug(fname) {" flash#{flash.inspect}"}
		@definitions = Definition.find_all_for(@current_user)
		unless @definitions.length==0
			respond_to do |format|
				format.html # new_process.html.erb
				format.xml { render :xml => @definitions.to_xml(:request => request) }
				format.json { render :json => @definitions.to_json(:request => request) }
			end

		end
	end

	# GET /definitions/1
	# GET /definitions/1.xml
	#
	def show
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml { render :xml => @definition.to_xml(:request => request) }
			format.json { render :json => @definition.to_json(:request => request) }
		end
	end

	def show_
		@definition = Definition.find(params[:id])
		@roles=Role.get_all
	end

	# GET /definitions/:id/tree
	# GET /definitions/:id/tree.js
	#
	def tree
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"tree:begin:params=#{params}"}
		@definition = Definition.find(params[:id])
		#LOG.debug(fname){"def=#{@definition.inspect}"}
		uri = @definition.local_uri
		# TODO : reject outside definitions ?
		pdef = (open(uri).read rescue nil)
		#LOG.debug(fname){"tree:pdef=#{pdef}"}
		var = params[:var] || 'proc_tree'
		# TODO : use Rails callback thing (:callback)
		if RuoteKit.engine.nil?
				PlmServices.ruote_init
			end
			tree = pdef ?
			RuoteKit.engine.get_def_parser.parse(pdef) :
			nil
		LOG.debug(fname){"tree:definitions.tree=#{tree.inspect}"}
		render(
    :text => "var #{var} = #{tree.to_json};",
    :content_type => 'text/javascript')
	end

	# GET /definitions/new
	# GET /definitions/new.xml
	#
	def new
		@definition = Definition.new
		respond_to do |format|
			format.html # new.html.erb
			format.xml { render :xml => @definition.to_xml(:request => request) }
			format.json { render :json => @definition.to_json(:request => request) }
		end
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		@object_orig = Definition.find(params[:id])
		@object = @object_orig.duplicate(current_user)
		@definition=@object
		respond_to do |format|
			format.html
			format.xml  { render :xml => @object }
		end
	end

	# GET /definitions/1/edit
	#
	def edit
		@definition = Definition.find(params[:id])
	#@dg_locals = {
	#	:in_roles => @definition.roles_definitions,
	#	:out_roles => Role.find(:all) - @definition.roles
	#}
	end

	# POST /definitions
	# POST /definitions.xml
	#
	def create
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"begin:params=#{params}"}
		@definition = Definition.new(params[:definition])
		@definition.rubyize!
		respond_to do |format|
			if fonct_new_dup?
				object_orig=Definition.find(params[:object_orig_id])
			st = @definition.create_duplicate(object_orig)
			else
			st = @definition.save!
			end
			if st
				flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_definition), :ident => @definition.name)
				LOG.debug(fname){"flash=#{flash}"}
				params[:id]=@definition.id
				show_
				format.html { render :action => "show" }
				format.xml {
					render(
          :xml => @definition.to_xml(:request => request),
          :status => :created,
          :location => @definition)
				}
				format.json {
					render(
          :json => @definition.to_json(:request => request),
          :status => :created,
          :location => @definition)
				}

			else
			#LOG.error @definition.errors.inspect
			#LOG.error @definition.inspect
				flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_definition), :msg => nil)
				format.html {
					render(:action => 'new')
				}
				format.xml {
					render(:xml => @definition.errors, :status => :unprocessable_entity)
				}
				format.json {
					render(:json => @definition.errors, :status => :unprocessable_entity)
				}
			end
		end
	end

	# PUT /definitions/1
	# PUT /definitions/1.xml
	#
	def update
		fname= "#{self.class.name}.#{__method__}"
		@definition = Definition.find(params[:id])
		@definition.update_accessor(current_user)
		@definition.rubyize!
		respond_to do |format|
			st=@definition.update_attributes(params[:definition])
			LOG.debug(fname) {"definition.errors=#{@definition.errors.full_messages}"}
			unless st.nil?
				LOG.debug(fname) {"definition=#{@definition.inspect}"}
				LOG.debug(fname) {"roles=#{@definition.roles.inspect}"}
				flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_definition), :ident => @definition.name)
				show_
				format.html { render :action => "show" }
				format.xml { head :ok }
				format.json { head :ok }
			else # there is an error
				LOG.error @definition.errors.full_messages
				LOG.error @definition.inspect
				flash[:error] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_definition), :ident => @definition.name, :error => @definition.errors.full_messages)
				format.html {
					render(:action => 'edit')
				}
				format.xml {
					render(:xml => @definition.errors, :status => :unprocessable_entity)
				}
				format.json {
					render(:json => @definition.errors, :status => :unprocessable_entity)
				}
			end
		end
	end

	private

end

