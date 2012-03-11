class ViewsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  access_control (Access.find_for_controller(controller_class_name()))
  # GET /views
  # GET /views.xml
  def index
    @views = View.find_paginate({:user=> current_user,:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @views }
    end
  end

  # GET /views/1
  # GET /views/1.xml
  def show
    @view = View.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @view }
    end
  end

  # GET /views/new
  # GET /views/new.xml
  def new
    @view = View.new
    @relations=Relation.all
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @view }
    end
  end

  # GET /views/1/edit
  def edit

    @view = View.find(params[:id])
    @relations=Relation.all
  end

  # POST /views
  # POST /views.xml
  def create
    @view = View.new(params[:view])
    @relations=Relation.all
    respond_to do |format|
      if @view.save
        flash[:notice] = t(:ctrl_object_created,:typeobj => t(:ctrl_view), :ident=>@view.name)
        format.html { redirect_to(@view) }
        format.xml  { render :xml => @view, :status => :created, :location => @view }
      else
        flash[:notice] = t(:ctrl_object_not_created,:typeobj => t(:ctrl_view), :ident=>@view.name, :msg => nil)
        format.html { render :action => "new" }
        format.xml  { render :xml => @view.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /views/1
  # PUT /views/1.xml
  def update
    @view = View.find(params[:id])
    @relations=Relation.all
    respond_to do |format|
      if @view.update_attributes(params[:view])
        flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_view),:ident=>@view.name)
        format.html { redirect_to(@view) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_view),:ident=>@view.name)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @view.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /views/1
  # DELETE /views/1.xml
  def destroy
    @view = View.find(params[:id])
    @view.destroy

    respond_to do |format|
      format.html { redirect_to(views_url) }
      format.xml  { head :ok }
    end
  end
end
