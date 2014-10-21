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
class GroupsController < ApplicationController
	include Controllers::PlmObjectControllerModule
	###before_filter :login_required
	# GET /groups
	# GET /groups.xml
	#
	def index

		@groups = Group.find_paginate({:user=> current_user, :filter_types => params[:filter_types], :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })

		respond_to do |format|
			format.html # index.html.erb
			format.xml { render :xml => @groups }
			format.json { render :json => @groups }
		end
	end

	# GET /groups/1
	# GET /groups/1.xml
	#
	def show
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @group }
			format.json  { render :json => @group }
		end
	end

	def select_view
		if params["commit"].force_encoding("utf-8") == t("root_model_design").force_encoding("utf-8")
			show_design
		else
			show_
			respond_to do |format|
				format.html { redirect_to(@group) }
			end
		end
	end

	def show_
		define_view
		@group = Group.find(params[:id])
		@tree  = build_tree(@group, @view_id)
		@object_plm = @group
	end

	# GET /groups/new
	# GET /groups/new.xml
	#
	def new
		@group = Group.new
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @group }
			format.json  { render :json => @group }
		end
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		@object_orig = Group.find(params[:id])
		@object = @object_orig.duplicate(current_user)
		@group=@object
		respond_to do |format|
			format.html
			format.xml  { render :xml => @object }
		end
	end

	# GET /groups/1/edit
	#
	def edit

		@group = Group.find(params[:id])
		@ug_locals = {
			:in_elements => @group.users || [],
			:out_elements => User.find(:all) - @group.users
		}
	end

	# POST /groups
	# POST /groups.xml
	#
	def create
		@group = Group.new(params[:group])
		respond_to do |format|
			if fonct_new_dup?
				object_orig=Group.find(params[:object_orig_id])
			st = @group.create_duplicate(object_orig)
			else
			st = @group.save
			end
			if st
				flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_group), :ident => @group.name)
				format.html { redirect_to(@group) }
				format.xml  { render :xml => @group, :status => :created, :location => @group }
			else
				flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_group), :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /groups/1
	# PUT /groups/1.xml
	#
	def update
		@group = Group.find(params[:id])
		@group.update_accessor(current_user)
		respond_to do |format|
			if @group.update_attributes(params[:group])
				flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_group), :ident => @group.name)
				format.html { redirect_to(@group) }
				format.xml  { head :ok }
			else
				flash[:error] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_group), :ident => @group.name)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /groups/1
	# DELETE /groups/1.xml
	#
	def destroy

		@group = Group.find(params[:id])
		@group.destroy

		respond_to do |format|
			format.html { redirect_to(groups_url) }
			format.xml  { head :ok }
		end
	end

end

