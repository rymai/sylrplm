class AccessesController < ApplicationController
  include Controllers::PlmObjectControllerModule
  access_control(Access.find_for_controller(controller_class_name))
  
  # GET /accesses
  # GET /accesses.xml
  def index
    @accesses = Access.find_paginate({ :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @accesses[:recordset] }
    end
  end
  
  # GET /accesses/1
  # GET /accesses/1.xml
  def show
    @access = Access.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @access }
    end
  end
  
  # GET /accesses/new
  # GET /accesses/new.xml
  def new
    @access      = Access.new
    @controllers = Controller.get_controllers
    @roles       = Role.findall_except_admin
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @access }
    end
  end
  
  # GET /accesses/1/edit
  def edit
    @access      = Access.find(params[:id])
    @controllers = Controller.get_controllers
    @roles       = Role.all
  end
  
  # POST /accesses
  # POST /accesses.xml
  def create
    @controllers = Controller.get_controllers
    @roles       = Role.findall_except_admin
    error        = false
    unless params[:access][:controller].nil?
      respond_to do |format|
        flash[:notice] = ""
        params[:access][:controller].each do |cont|
          @access = Access.create_new(cont,params[:access][:role_id])
          if @access.save
            flash[:notice] += '<br />'+ t(:ctrl_object_created, :object => 'Access', :ident => @access.controller)
            format.html { redirect_to(@access) }
            format.xml  { render :xml => @access, :status => :created, :location => @access }
          else
            @access = Access.new
            flash[:notice] += '<br />'+t(:ctrl_object_not_created, :object => 'Access')
            format.html { render :action => "new" }
            format.xml  { render :xml => @access.errors, :status => :unprocessable_entity }
          end
        end
      end
    else
      @access      = Access.new
      @controllers = Controller.get_controllers
      @roles       = Role.all
      respond_to do |format|
        flash[:notice] = t(:ctrl_object_no_controlers,:object=>'Access')
        format.html { render :action => "new" }
        format.xml  { render :xml => @access }
      end
    end
  end
  
  # PUT /accesses/1
  # PUT /accesses/1.xml
  def update
    @access      = Access.find(params[:id])
    @controllers = Controller.get_controllers
    @roles       = Role.all
    respond_to do |format|
      if @access.update_attributes(params[:access])
        flash[:notice] = t(:ctrl_object_updated, :object => 'Access', :ident => @access.controller)
        format.html { redirect_to(@access) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_notupdated, :object => 'Access', :ident => @access.controller)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @access.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /accesses/1
  # DELETE /accesses/1.xml
  def destroy
    @access = Access.find(params[:id])
    @access.destroy
    flash[:notice] = t(:ctrl_object_deleted, :object => 'Access', :ident => @access.controller)
    respond_to do |format|
      format.html { redirect_to(accesses_url) }
      format.xml  { head :ok }
    end
  end
end