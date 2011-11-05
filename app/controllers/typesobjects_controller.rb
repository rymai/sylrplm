class TypesobjectsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  access_control (Access.find_for_controller(controller_class_name()))
  # GET /typesobjects
  # GET /typesobjects.xml
  def index
    @typesobjects = Typesobject.find_paginate({:user=> current_user,:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @typesobjects }
    end
  end

  # GET /typesobjects/1
  # GET /typesobjects/1.xml
  def show
    @typesobject = Typesobject.find(params[:id])
    # objets pouvant etre types

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @typesobject }
    end
  end

  # GET /typesobjects/new
  # GET /typesobjects/new.xml
  def new
    @typesobject = Typesobject.new
    @objectswithtype=Typesobject.get_objects_with_type
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @typesobject }
    end
  end

  # GET /typesobjects/1/edit
  def edit
    @typesobject = Typesobject.find(params[:id])
    @objectswithtype=Typesobject.get_objects_with_type
  end

  # POST /typesobjects
  # POST /typesobjects.xml
  def create
    @typesobject = Typesobject.new(params[:typesobject])
    @objectswithtype=Typesobject.get_objects_with_type
    respond_to do |format|
      if @typesobject.save
        flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_typesobject),:ident=>@typesobject.name)
        format.html { redirect_to(@typesobject) }
        format.xml  { render :xml => @typesobject, :status => :created, :location => @typesobject }
      else
        flash[:notice] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_typesobject),:ident=>@typesobject.name, :msg => nil)
        format.html { render :action => "new" }
        format.xml  { render :xml => @typesobject.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /typesobjects/1
  # PUT /typesobjects/1.xml
  def update
    @typesobject = Typesobject.find(params[:id])
    @objectswithtype=Typesobject.get_objects_with_type
    @typesobject.update_accessor(current_user)
    respond_to do |format|
      if @typesobject.update_attributes(params[:typesobject])
        flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_typesobject),:ident=>@typesobject.name)
        format.html { redirect_to(@typesobject) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_typesobject),:ident=>@typesobject.name)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @typesobject.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /typesobjects/1
  # DELETE /typesobjects/1.xml
  def destroy
    @typesobject = Typesobject.find(params[:id])
    @typesobject.destroy
    respond_to do |format|
      flash[:notice] = t(:ctrl_object_deleted,:typeobj =>t(:ctrl_typesobject),:ident=>@typesobject.name)
      format.html { redirect_to(typesobjects_url) }
      format.xml  { head :ok }
    end
  end
end
