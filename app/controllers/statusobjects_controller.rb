#
#  statusobjects_controller.rb
#  sylrplm
#
#  Created by Sylvère on 2012-02-02.
#  Copyright 2012 Sylvère. All rights reserved.
#
class StatusobjectsController < ApplicationController
	include Controllers::PlmObjectControllerModule
	access_control (Access.find_for_controller(controller_class_name()))
	# GET /statusobjects
	# GET /statusobjects.xml
	def index
		@statusobjects = Statusobject.find_paginate({:user=> current_user,:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @statusobjects }
		end
	end

	# GET /statusobjects/1
	# GET /statusobjects/1.xml
	def show
		@statusobject = Statusobject.find(params[:id])
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @statusobject }
		end
	end

	# GET /statusobjects/new
	# GET /statusobjects/new.xml
	def new
		@statusobject = Statusobject.new
		@types    = ::Typesobject.find(:all, :order => "name", :conditions => ["forobject = '#{@statusobject.forobject}'"])
		@objectswithstatus=Statusobject.get_objects_with_status
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @statusobject }
		end
	end

	# GET /statusobjects/1/edit
	def edit
		@statusobject = Statusobject.find(params[:id])
		@types    = ::Typesobject.find(:all, :order => "name", :conditions => ["forobject = '#{@statusobject.forobject}'"])
		@objectswithstatus=Statusobject.get_objects_with_status
	end

	# POST /statusobjects
	# POST /statusobjects.xml
	def create
		@statusobject = Statusobject.new(params[:statusobject])
		@types    = ::Typesobject.find(:all, :order => "name", :conditions => ["forobject = '#{@statusobject.forobject}'"])
		@objectswithstatus=Statusobject.get_objects_with_status
		respond_to do |format|
			if @statusobject.save
				flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_statusobject),:ident=>@statusobject.name)
				format.html { redirect_to(@statusobject) }
				format.xml  { render :xml => @statusobject, :status => :created, :location => @statusobject }
			else
				flash[:error] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_statusobject),:ident=>@statusobject.name, :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @statusobject.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /statusobjects/1
	# PUT /statusobjects/1.xml
	def update
		@statusobject = Statusobject.find(params[:id])
		@objectswithstatus=Statusobject.get_objects_with_status
		@statusobject.update_accessor(current_user)
		respond_to do |format|
			if @statusobject.update_attributes(params[:statusobject])
				flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_statusobject),:ident=>@statusobject.name)
				format.html { redirect_to(@statusobject) }
				format.xml  { head :ok }
			else
				flash[:error] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_statusobject),:ident=>@statusobject.name)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @statusobject.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /statusobjects/1
	# DELETE /statusobjects/1.xml
	def destroy
		@statusobject = Statusobject.find(params[:id])
		if @statusobject.destroy
			flash[:notice] = t(:ctrl_object_deleted,:typeobj =>t(:ctrl_statusobject),:ident=>@statusobject.name)
		else
			flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_statusobject),:ident=>@statusobject.name)
		end
		respond_to do |format|
			format.html { redirect_to(statusobjects_url) }
			format.xml  { head :ok }
		end
	end
end
