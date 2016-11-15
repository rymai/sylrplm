class RolesController < ApplicationController
	include Controllers::PlmObjectControllerModule
	access_control (Access.find_for_controller(controller_name.classify))
	# GET /roles
	# GET /roles.xml
	def index
		index_
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @roles }
		end
	end

	def index_
		@roles = Role.find_paginate({:user=> current_user, :filter_types => params[:filter_types],:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
		@object_plms=@roles
	end

	def index_execute
		ctrl_index_execute
	end

	# GET /roles/1
	# GET /roles/1.xml
	def show
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @role }
		end
	end

	def select_view
		if params["commit"].force_encoding("utf-8") == t("root_model_design").force_encoding("utf-8")
			show_design
		else
			show_
			respond_to do |format|
				format.html { redirect_to(@role) }
			end
		end
	end

	# GET /roles/new
	# GET /roles/new.xml
	def new
		@role = Role.new
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @role }
		end
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		@object_orig = Role.find(params[:id])
		@object = @object_orig.duplicate(current_user)
		@role = @object
		respond_to do |format|
			format.html
			format.xml  { render :xml => @object }
		end
	end

	# GET /roles/1/edit
	def edit
		@role = Role.find(params[:id])
	end

	# POST /roles
	# POST /roles.xml
	def create
		@role = Role.new(params[:role])
		respond_to do |format|
			if fonct_new_dup?
				object_orig=Role.find(params[:object_orig_id])
			st = @role.create_duplicate(object_orig)
			else
			st = @role.save
			end
			if st
				flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_role),:ident=>@role.title)
				params[:id]=@role.id
				show_
				format.html { render :action => "show" }
				format.xml  { render :xml => @role, :status => :created, :location => @role }
			else
				flash[:error] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_role),:ident=>@role.title, :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /roles/1
	# PUT /roles/1.xml
	def update
		@role = Role.find(params[:id])
		@role.update_accessor(current_user)
		respond_to do |format|
			if @role.update_attributes(params[:role])
				flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_role),:ident=>@role.title)
				show_
				format.html { render :action => "show" }
				format.xml  { head :ok }
			else
				flash[:error] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_role),:ident=>@role.title, :error => @role.errors.full_messages)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
			end
		end
	end

	private

	def show_
		define_view
		@role = Role.find(params[:id])
		@tree  = build_tree(@role, @view_id)
		@object_plm = @role
	end

end
