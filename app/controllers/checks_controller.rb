class ChecksController < ApplicationController
  include Controllers::PlmObjectControllerModule
  access_control(Access.find_for_controller(controller_name))
  before_filter :check_user, :only => [:new, :edit]
  # GET /checks
  # GET /checks.xml
  def index
    @checks = Check.find_paginate({:user=> current_user, :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items])})
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
    @check = Check.new
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
    @check = Check.new(params[:check])
    respond_to do |format|
      if @check.save
        flash[:notice] = '<br />' + t(:ctrl_object_created, :typeobj => 'Check', :ident => @check.id)
        format.html { redirect_to(@check) }
        format.xml  { render :xml => @check, :status => :created, :location => @check }
      else
        flash[:error] = '<br />'+t(:ctrl_object_not_created, :typeobj => 'Check', :msg => nil)
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
        flash[:notice] = t(:ctrl_object_updated, :typeobj => 'Check', :ident => @check.controller)
        format.html { redirect_to(@check) }
        format.xml  { head :ok }
      else
        flash[:error] = t(:ctrl_object_not_updated, :typeobj => 'Check', :ident => @check.controller)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @check.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /checks/1
  # DELETE /checks/1.xml
  def destroy
    @check = Check.find(params[:id])
    @check.destroy
    respond_to do |format|
      format.html { redirect_to(checks_url) }
      format.xml  { head :ok }
    end
  end
end
