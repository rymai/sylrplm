class AccessesController < ApplicationController
  include Controllers::PlmObjectControllerModule
  access_control(Access.find_for_controller(controller_class_name))

  before_filter :find_by_id, :only => [:show, :edit, :update, :destroy]
  before_filter :find_controllers, :only => [:new, :edit, :create, :update]
  # GET /accesses
  # GET /accesses.xml
  def index
    @accesses = Access.find_paginate({:user=> current_user, :page => params[:page], :query => params[:query], :sort => params[:sort] || 'controller, action', :nb_items => get_nb_items(params[:nb_items]) })
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @accesses[:recordset] }
    end
  end

  # GET /accesses/1
  # GET /accesses/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @access }
    end
  end

  # GET /accesses/new
  # GET /accesses/new.xml
  def new
    @access = Access.new
    @roles  = Role.findall_except_admin
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @access }
    end
  end

  # GET /accesses/1/edit
  def edit
    @roles = Role.all
  end

  # POST /accesses
  # POST /accesses.xml
  def create
    respond_to do |format|
      @access = Access.new(params[:access])
      if @access.save
        flash[:notice] = '<br />'+ t(:ctrl_object_created, :typeobj => 'Access', :ident => @access.controller, :msg => nil)
        format.html { redirect_to(@access) }
        format.xml  { render :xml => @access, :status => :created, :location => @access }
      else
        @roles = Role.findall_except_admin
        flash[:notice] = '<br />'+t(:ctrl_object_not_created, :typeobj => 'Access', :msg => nil)
        format.html { render :action => "new" }
        format.xml  { render :xml => @access.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /accesses/1
  # PUT /accesses/1.xml
  def update
    @access.update_accessor(current_user)
    respond_to do |format|
      if @access.update_attributes(params[:access])
        flash[:notice] = t(:ctrl_object_updated, :typeobj => 'Access', :ident => @access.controller)
        format.html { redirect_to(@access) }
        format.xml  { head :ok }
      else
        @roles = Role.all
        flash[:notice] = t(:ctrl_object_not_updated, :typeobj => 'Access', :ident => @access.controller)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @access.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /accesses/1
  # DELETE /accesses/1.xml
  def destroy
    @access.destroy
    flash[:notice] = t(:ctrl_object_deleted, :typeobj => 'Access', :ident => @access.controller)
    respond_to do |format|
      format.html { redirect_to(accesses_url) }
      format.xml  { head :ok }
    end
  end

  def reset
    #puts __FILE__+"."+__method__.to_s+":params="+params.inspect
    #on refait les autorisations:
    # - apres l'ajout d'un controller (rare et manuel)
    # - apres ajout/suppression de role (peut etre automatise)
    st=Access.reset
    @accesses = Access.find_paginate({ :page => params[:page], :query => params[:query], :sort => params[:sort] || 'controller, action', :nb_items => get_nb_items(params[:nb_items]) })
    respond_to do |format|
      format.html { redirect_to(accesses_path)  }
      format.xml  { render :xml => @accesses[:recordset] }
    end
  end

  private

  def find_by_id
    @access = Access.find(params[:id])
  end

  def find_controllers
    @controllers = Controller.get_controllers_and_methods
  end

end