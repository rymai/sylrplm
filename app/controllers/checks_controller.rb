class ChecksController < ApplicationController
	include Controllers::PlmObjectController
	access_control(Access.find_for_controller(controller_name.classify))
	# GET /checks
	# GET /checks.xml
	def index
		@checks = Check.find_paginate({:user=> current_user, :filter_types => params[:filter_types], :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items])})
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @checks[:recordset] }
		end
	end

	# GET /checks/1
	# GET /checks/1.xml
	def show
		@check = Check.find(params[:id])
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @check }
		end
	end

	# GET /checks/new
	# GET /checks/new.xml
	def new
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"params=#{params.inspect}"}
		@check = Check.new(:user => current_user)
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @check }
		end
	end

	# GET /checks/1/edit
	def edit
		@check = Check.find(params[:id])
	end

	# POST /checks
	# POST /checks.xml
	def create
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"params=#{params.inspect}"}
		@check = Check.new(params[:check])
		@check.owner=current_user unless current_user.nil?
		respond_to do |format|
			if @check.save
				LOG.debug(fname) {"@check.owner.name=#{@check.owner.login}"}
				flash[:notice] = t(:ctrl_object_created, :typeobj => 'Check', :ident => @check.id)
				format.html { redirect_to(@check) }
				format.xml  { render :xml => @check, :status => :created, :location => @check }
			else
				flash[:error] = t(:ctrl_object_not_created, :typeobj => 'Check', :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @check.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /checks/1
	# PUT /checks/1.xml
	def update
		@check = Check.find(params[:id])
		@check.update_accessor(current_user)
		respond_to do |format|
			if @check.update_attributes(params[:check])
				flash[:notice] = t(:ctrl_object_updated, :typeobj => 'Check', :ident => @check.ident)
				format.html { redirect_to(@check) }
				format.xml  { head :ok }
			else
				flash[:error] = t(:ctrl_object_not_updated, :typeobj => 'Check', :ident => @check.ident, :error => @check.errors.full_messages)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @check.errors, :status => :unprocessable_entity }
			end
		end
	end

end