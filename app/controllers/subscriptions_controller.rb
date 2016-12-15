class SubscriptionsController < ApplicationController
	include Controllers::PlmObjectController
	before_filter :authorize, :except => nil
	access_control(Access.find_for_controller(controller_name.classify))
	# GET /subscriptions
	# GET /subscriptions.xml
	def index
		index_
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @subscriptions }
		end
	end

	def index_
		if params.include? :current_user
			authorize
			params[:query] = current_user.login
		end
		@subscriptions = Subscription.find_paginate({:user=> current_user, :filter_types => params[:filter_types],:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})

	end

	def index_execute
		ctrl_index_execute
	end

	# GET /subscriptions/1
	# GET /subscriptions/1.xml
	def show
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @subscription }
		end
	end

	# GET /subscriptions/new
	# GET /subscriptions/new.xml
	def new
		@subscription = Subscription.new(user: current_user)
		@ingroups  = Group.all
		@inprojects  = Project.all
		@fortypesobjects = Typesobject.get_from_observer
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @subscription }
		end
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		@object_orig = Subscription.find(params[:id])
		@object = @object_orig.duplicate(current_user)
		@subscription=@object
		respond_to do |format|
			format.html
			format.xml  { render :xml => @object }
		end
	end

	# GET /subscriptions/1/edit
	def edit
		@subscription = Subscription.find(params[:id])
		@ingroups  = Group.all
		@inprojects  = Project.all
		@fortypesobjects=Typesobject.get_from_observer
	end

	# POST /subscriptions
	# POST /subscriptions.xml
	def create
		@subscription = Subscription.new(params[:subscription])
		respond_to do |format|
			if fonct_new_dup?
				object_orig=Subscription.find(params[:object_orig_id])
			st = @subscription.create_duplicate(object_orig)
			else
			st = @subscription.save
			end
			if st
				#format.html { redirect_to(@subscription, :notice => 'Subscription was successfully created.') }
				flash[:notice] = 'Subscription was successfully created.'
				params[:id]= @subscription.id
				show_
				format.html { render :action => "show" }
				format.xml  { render :xml => @subscription, :status => :created, :location => @subscription }
			else
				@ingroups  = Group.all
				@inprojects  = Project.all
				@fortypesobjects=Typesobject.get_from_observer
				format.html { render :action => "new" }
				format.xml  { render :xml => @subscription.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /subscriptions/1
	# PUT /subscriptions/1.xml
	def update
		@subscription = Subscription.find(params[:id])
		respond_to do |format|
			if @subscription.update_attributes(params[:subscription])
				flash[:notice] = 'Subscription was successfully updated.'
				show_
				format.html { render :action => "show" }
				format.xml  { head :ok }
			else
				@ingroups  = Group.all
				@inprojects  = Project.all
				@fortypesobjects=Typesobject.get_from_observer
				format.html { render :action => "edit" }
				format.xml  { render :xml => @subscription.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /subscriptions/1
	# DELETE /subscriptions/1.xml
	def destroy_old
		@subscription = Subscription.find(params[:id])
		@subscription.destroy

		respond_to do |format|
			format.html { redirect_to(subscriptions_url) }
			format.xml  { head :ok }
		end
	end
	private

	def show_
		@subscription = Subscription.find(params[:id])
	end
end
