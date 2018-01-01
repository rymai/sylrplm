class GroupsController < ApplicationController
	include Controllers::PlmObjectController
	###before_filter :login_required
	# GET /groups
	# GET /groups.xml
	#
	def index
		ctrl_index
	end

	def index_old
		index_
		respond_to do |format|
			format.html # index.html.erb
			format.xml { render :xml => @groups }
			format.json { render :json => @groups }
		end
	end

	def index_
		fname= "#{self.class.name}.#{__method__}"
		@groups = Group.find_paginate({:user=> current_user, :filter_types => params[:filter_types], :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
		@object_plms=@groups
		LOG.debug(fname){"@groups=#{@groups}"}
		#LOG.debug(fname){"@object_plms=#{@object_plms}"}
	end

	def index_execute
		ctrl_index_execute
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
			:out_elements => User.all - @group.users
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
				params[:id]=@group.id
				show_
				format.html { render :action => "show" }
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
				show_
				format.html { render :action => "show" }
				format.xml  { head :ok }
			else
				flash[:error] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_group), :ident => @group.name, :error => @group.errors.full_messages)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
			end
		end
	end

end

