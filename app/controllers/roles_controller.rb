class RolesController < ApplicationController
  include Controllers::PlmObjectControllerModule
  access_control (Access.find_for_controller(controller_class_name()))
  # GET /roles
  # GET /roles.xml
  def index
    
    @roles = Role.find_paginate({:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])}) 
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @roles }
    end
  end
  
  # GET /roles/1
  # GET /roles/1.xml
  def show
    @role = Role.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @role }
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
  
  # GET /roles/1/edit
  def edit
    @role = Role.find(params[:id])
  end
  
  # POST /roles
  # POST /roles.xml
  def create
    @role = Role.new(params[:role])
    respond_to do |format|
      if @role.save
        flash[:notice] = t(:ctrl_object_created,:object=>t(:ctrl_role),:ident=>@role.title)
        format.html { redirect_to(@role) }
        format.xml  { render :xml => @role, :status => :created, :location => @role }
      else
        flash[:notice] = t(:ctrl_object_not_created,:object=>t(:ctrl_role),:ident=>@role.title)
        format.html { render :action => "new" }
        format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /roles/1
  # PUT /roles/1.xml
  def update
    @role = Role.find(params[:id])
    
    respond_to do |format|
      if @role.update_attributes(params[:role])
        flash[:notice] = t(:ctrl_object_updated,:object=>t(:ctrl_role),:ident=>@role.title)
        format.html { redirect_to(@role) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_updated,:object=>t(:ctrl_role),:ident=>@role.title)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /roles/1
  # DELETE /roles/1.xml
  def destroy
    @role = Role.find(params[:id])
    @role.destroy
    respond_to do |format|
      flash[:notice] = t(:ctrl_object_deleted,:object=>t(:ctrl_role),:ident=>@role.title)
      format.html { redirect_to(roles_url) }
      format.xml  { head :ok }
    end
  end
end
