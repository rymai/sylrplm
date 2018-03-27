# frozen_string_literal: true

class AccessesController < ApplicationController
  include Controllers::PlmObjectController
  #
  access_control(Access.find_for_controller(controller_name.classify))
  before_filter :find_by_id, only: [:show, :edit, :update, :destroy]
  before_filter :find_controllers, only: [:new, :new_dup, :edit, :create, :update]
  # GET /accesses
  # GET /accesses.xml
  def index
    fname = "#{self.class.name}.#{__method__}"
    @accesses = Access.find_paginate(user: current_user, filter_types: params[:filter_types], page: params[:page], query: params[:query], sort: params[:sort] || 'controller, action', nb_items: get_nb_items(params[:nb_items]))
    actions_by_roles = Access.get_actions_by_roles
    @accesses[:actions_by_roles] = actions_by_roles
    LOG.debug(fname) { "access=#{@accesses}" }
    @tree = build_tree_actions_by_roles(actions_by_roles)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @accesses }
    end
  end

  # GET /accesses/1
  # GET /accesses/1.xml
  def show
    show_
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @access }
    end
  end

  def show_; end

  # GET /accesses/new
  # GET /accesses/new.xml
  def new
    @access = Access.new
    @roles = Role.findall_except_admin
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @access }
    end
  end

  def new_dup
    fname = "#{self.class.name}.#{__method__}"
    @roles = Role.findall_except_admin
    @object_orig = Access.find(params[:id])
    @object = @object_orig.duplicate(current_user)
    @access = @object
    respond_to do |format|
      format.html
      format.xml { render xml: @object }
    end
  end

  # GET /accesses/1/edit
  def edit
    @roles = Role.all
  end

  # POST /accesses
  # POST /accesses.xml
  def create
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "params=#{params}" }
    respond_to do |format|
      par = Access.prepare(params[:access])
      LOG.debug(fname) { "par=#{par}" }
      @access = Access.new(par)
      LOG.debug(fname) { "@access=#{@access}" }
      if fonct_new_dup?
        object_orig = Access.find(params[:object_orig_id])
        st = @access.create_duplicate(object_orig)
      else
        st = @access.save
      end
      if st
        flash[:notice] = t(:ctrl_object_created, typeobj: 'Access', ident: @access.controller, msg: nil)
        params[:id] = @access.id
        show_
        format.html { render action: 'show' }
        format.xml  { render xml: @access, status: :created, location: @access }
      else
        @roles = Role.findall_except_admin
        flash[:error] = t(:ctrl_object_not_created, typeobj: 'Access', msg: nil)
        format.html { render action: 'new' }
        format.xml  { render xml: @access.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /accesses/1
  # PUT /accesses/1.xml
  def update
    @access.update_accessor(current_user)
    respond_to do |format|
      if @access.update_attributes(params[:access])
        flash[:notice] = t(:ctrl_object_updated, typeobj: 'Access', ident: @access.controller)
        show_
        format.html { render action: 'show' }
        format.xml  { head :ok }
      else
        @roles = Role.all
        flash[:error] = t(:ctrl_object_not_updated, typeobj: 'Access', ident: @access.controller, error: @access.errors.full_messages)
        format.html { render action: 'edit' }
        format.xml  { render xml: @access.errors, status: :unprocessable_entity }
      end
    end
  end

  def reset
    # puts __FILE__+"."+__method__.to_s+":params="+params.inspect
    # on refait les autorisations:
    # - apres l'ajout d'un controller (rare et manuel)
    # - apres ajout/suppression de role (peut etre automatise)
    Access.reset
    @accesses = Access.find_paginate(page: params[:page], filter_types: params[:filter_types], query: params[:query], sort: params[:sort] || 'controller, action', nb_items: get_nb_items(params[:nb_items]))
    respond_to do |format|
      format.html { redirect_to(accesses_path) }
      format.xml  { render xml: @accesses[:recordset] }
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
