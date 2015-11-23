class ForumItemsController < ApplicationController
	include Controllers::PlmObjectControllerModule
	access_control(Access.find_for_controller(controller_class_name))
	# GET /forum_items
	# GET /forum_items.xml
	def index
		@forum_items = ForumItem.find_paginate({:user=> current_user, :filter_types => params[:filter_types], :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @forum_items }
		end
	end

	# GET /forum_items/1
	# GET /forum_items/1.xml
	def show
		show
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @forum_item }
		end
	end
	def show_
		@forum_item = ForumItem.find(params[:id])
	end
	# GET /forum_items/new
	# GET /forum_items/new.xml
	def new
		unless params[:forum_id].nil?
			@forum                = Forum.find(params[:forum_id])
			@forum_item           = ForumItem.new(user: current_user)
			@forum_item.forum     = @forum
			@forum_item.message   = "..."
			@forum_item.author    = @current_user
			@forum_item.parent_id = params[:parent_id]
		else
			@forum_item = ForumItem.new(user: current_user)
		end
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @forum_item }
		end
	end

	# GET /forum_items/1/edit
	def edit
		@forum_item = ForumItem.find(params[:id])
	end

	# POST /forum_items
	# POST /forum_items.xml
	def create
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname){"params=#{params.inspect}"}
		@forum_item = ForumItem.new(params[:forum_item])
		respond_to do |format|
			if @forum_item.save
				flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_forum_item), :ident => @forum_item.id)
				params[:id]=@forum_item.id
				format.html { redirect_to(@forum_item.forum) }
				format.xml  { render :xml => @forum_item, :status => :created, :location => @forum_item }
			else
				flash[:error] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_forum_item), :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @forum_item.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /forum_items/1
	# PUT /forum_items/1.xml
	def update
		@forum_item = ForumItem.find(params[:id])
		@forum_item.update_accessor(current_user)
		respond_to do |format|
			if @forum_item.update_attributes(params[:forum_item])
				flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_forum_item), :ident => @forum_item.id)
				show_
				format.html { render :action => "show" }
				format.xml  { head :ok }
			else
				flash[:error] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_forum_item),:ident=>@forum_item.id, :error => @forum_item.errors.full_messages)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @forum_item.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /forum_items/1
	# DELETE /forum_items/1.xml
	def destroy
		@forum_item = ForumItem.find(params[:id])
		@forum      = @forum_item.forum
		@forum_item.destroy
		respond_to do |format|
			flash[:notice] = flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_forum_item), :ident => @forum_item.id)
			format.html { redirect_to(@forum) }
			format.xml  { head :ok }
		end
	end

end