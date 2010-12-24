class StatusobjectsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  access_control (Access.find_for_controller(controller_class_name()))
  # GET /statusobjects
  # GET /statusobjects.xml
  def index
  @statusobjects = Statusobject.find_paginate({:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])}) 
     
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
    @statusobject = Statusobject.new(params[:statusobject])
    @objectswithstatus=Statusobject.get_objects_with_status
    @objectswithstatus.each do |v|
      puts controller_class_name()+".new:@objectswithstatus="+v
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @statusobject }
    end
  end
  
  # GET /statusobjects/1/edit
  def edit
    @statusobject = Statusobject.find(params[:id])
    @objectswithstatus=Statusobject.get_objects_with_status
  end
  
  # POST /statusobjects
  # POST /statusobjects.xml
  def create
    @statusobject = Statusobject.new(params[:statusobject])
    @objectswithstatus=Statusobject.get_objects_with_status
    respond_to do |format|
      if @statusobject.save
        flash[:notice] = t(:ctrl_object_created,:object=>t(:ctrl_statusobject),:ident=>@statusobject.name)
        format.html { redirect_to(@statusobject) }
        format.xml  { render :xml => @statusobject, :status => :created, :location => @statusobject }
      else
        flash[:notice] = t(:ctrl_object_not_created,:object=>t(:ctrl_statusobject),:ident=>@statusobject.name)
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
    respond_to do |format|
      if @statusobject.update_attributes(params[:statusobject])
        flash[:notice] = t(:ctrl_object_updated,:object=>t(:ctrl_statusobject),:ident=>@statusobject.name)
        format.html { redirect_to(@statusobject) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_updated,:object=>t(:ctrl_statusobject),:ident=>@statusobject.name)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @statusobject.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /statusobjects/1
  # DELETE /statusobjects/1.xml
  def destroy
    @statusobject = Statusobject.find(params[:id])
    @statusobject.destroy
    
    respond_to do |format|
      flash[:notice] = t(:ctrl_object_deleted,:object=>t(:ctrl_statusobject),:ident=>@statusobject.name)
      format.html { redirect_to(statusobjects_url) }
      format.xml  { head :ok }
    end
  end
end
