# frozen_string_literal: true

class UsersController < ApplicationController
  include Controllers::PlmObjectController
  # #include CheckboxSelectable
  #

  access_control(Access.find_for_controller(controller_name.classify))

  # GET /users
  # GET /users.xml
  def index
    index_
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @current_users }
    end
  end

  def index_
    fname = "#{self.class.name}.#{__method__}"
    @current_users = User.find_paginate(user: current_user, filter_types: params[:filter_types], page: params[:page], query: params[:query], sort: params[:sort], nb_items: get_nb_items(params[:nb_items]))
    # LOG.info(fname) {"@current_users=#{@current_users}"}
    @object_plms = @current_users
  end

  def index_execute
    ctrl_index_execute
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    show_
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @the_user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    # ##@the_user = User.create_new
    @the_user = User.new(user: current_user)
    @roles   = Role.all
    @groups  = Group.all
    @object_plms = Project.all
    @themes = get_themes(@theme)
    @time_zones = get_time_zones(@time_zone)
    @volumes = Volume.all.to_a
    @types = Typesobject.get_types('user')
    @subscriptions = Subscription.all
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @the_user }
    end
  end

  def new_dup
    fname = "#{self.class.name}.#{__method__}"
    @object_orig = User.find(params[:id])
    @object = @object_orig.duplicate(current_user)
    @the_user = @object
    @roles   = Role.all
    @groups  = Group.all
    @object_plms = Project.all
    @themes = get_themes(@theme)
    @time_zones = get_time_zones(@time_zone)
    @volumes = Volume.all.to_a
    @types = Typesobject.get_types('user')
    @subscriptions = Subscription.all
    respond_to do |format|
      format.html
      format.xml { render xml: @object }
    end
  end

  # GET /users/1/edit
  def edit
    @the_user = User.find(params[:id])
    @roles   = Role.all
    @groups  = Group.all
    @object_plms = Project.all
    @themes = get_themes(@theme)
    @time_zones = get_time_zones(@the_user.time_zone)
    @volumes = Volume.all.to_a
    @types = Typesobject.get_types('user')
    @subscriptions = Subscription.all
  end

  # GET /users/1/reset_passwd
  def reset_passwd
    @the_user = User.find(params[:id])
    @the_user.reset_passwd
    respond_to do |format|
      if @the_user.save
        flash.now[:notice] = t(:ctrl_user_updated, user: @the_user.login)
        format.html { render action: 'show' }
        format.xml  { render xml: the_user, status: :updated, location: @the_user }
      else
        flash.now[:error] = t(:ctrl_user_not_updated, user: @the_user.login, msg: @the_user.errors.inspect)
        format.html { render action: 'edit' }
        format.xml  { render xml: @the_user.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @the_user = User.new(params[:user])
    @the_user.def_user(current_user)
    respond_to do |format|
      if fonct_new_dup?
        object_orig = User.find(params[:object_orig_id])
        st = @the_user.create_duplicate(object_orig)
      else
        st = @the_user.save
      end
      if st
          #pour association has_many_and_belongs
                @the_user.update_attributes(params[:user])
        flash.now[:notice] = t(:ctrl_user_created, user: @the_user.login)
        params[:id] = @the_user.id
        show_
        format.html { render action: 'show' }
        format.xml  { render xml: @the_user, status: :created, location: @the_user }
      else
        @roles = Role.all
        @groups = Group.all
        @object_plms = Project.all
        @themes = get_themes(@theme)
        @time_zones = get_time_zones(@the_user.time_zone)
        @volumes = Volume.all
        @types = Typesobject.get_types('user')
        @subscriptions = Subscription.all
        flash.now[:error] = t(:ctrl_user_not_created, user: @the_user.login, msg: @the_user.errors.inspect[0,50])
        format.html { render action: 'new' }
        format.xml  { render xml: @the_user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    fname = "#{self.class.name}.#{__method__}"
    @the_user = User.find(params[:id])
    @volumes = Volume.all
    @roles   = Role.all
    @object_plms = Project.all
    @groups = Group.all
    @themes = get_themes(@theme)
    @time_zones = get_time_zones(@the_user.time_zone)
    @types = Typesobject.get_types('user')
    @the_user.update_accessor(current_user)
    # TODO: work around: the view users/_edit:<%= select_inout(f, @the_user, @roles, :title) %>
    # does not return any value if no value in the choosen list, then we force empty array here
    params_user = params[:user]
    # LOG.debug(fname){"params_user:roles=#{params_user[:role_ids]} groups=#{params_user[:group_ids]} projects=#{params_user[:project_ids]}"}
    respond_to do |format|
      if @the_user.update_attributes(params_user)
        flash[:notice] = t(:ctrl_user_updated, user: @the_user.login)
        show_
        format.html { render action: 'show' }
        format.xml  { head :ok }
      else
        @subscriptions = Subscription.all
        flash.now[:error] = t(:ctrl_user_not_updated, user: @the_user.login, msg: @the_user.errors.inspect)
        format.html { render action: 'edit' }
        format.xml  { render xml: @the_user.errors, status: :unprocessable_entity }
      end
    end
  end

  #
  # update of edit panel after changing the type
  #
  def update_type
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname){"params=#{params.inspect}"}
    @the_user = User.find(params[:id])
    ctrl_update_type @the_user, params[:object_type]
  end

  def destroy_old
    id = params[:id]
    if id && @the_user = User.find(id)
      if id != session[:user_id]
        begin
          @the_user.destroy
          flash[:notice] = t(:ctrl_user_deleted, user: @the_user.login)
        rescue Exception => e
          flash[:notice] = t(:ctrl_user_not_deleted, user: @the_user.login)
          flash[:notice] = e.message
        end
      else
        flash[:warn] = t(:ctrl_user_connected, user: @the_user.login)
      end
    end
    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml { head :ok }
    end
  end

  # GET /users/1/account_edit
  def account_edit
    @the_user = User.find(params[:id])
    @themes = get_themes(@theme)
    @time_zones = get_time_zones(@the_user.time_zone)
    @subscriptions = Subscription.all
    @volumes = Volume.get_all
  end

  # GET /users/1/account_edit_passwd
  def account_edit_passwd
    @the_user = User.find(params[:id])
  end

  def account_update
     @the_user = User.find(params[:id])
    @themes = get_themes(@theme)
    @time_zones = get_time_zones(@the_user.time_zone)
    @volumes = Volume.get_all
    ok = true
    if params[:user][:password].nil?
      if @the_user.update_attributes(params[:user])
        ok = true
      else
        msg = @the_user.errors.full_messages
        ok = false
      end
    else
      if params[:user][:password].empty?
        ok = false
        msg = t('password_needed')
      else
        if @the_user.update_attributes(params[:user])
          ok = true
        else
          msg = @the_user.errors.full_messages
          ok = false
        end
      end
    end

    respond_to do |format|
      if ok
        flash[:notice] = t(:ctrl_user_updated, user: @the_user.login)
        format.html { redirect_to('/main/tools') }
        format.xml  { head :ok }
      else
        flash[:error] = t(:ctrl_user_not_updated, user: @the_user.login, msg: msg)
        format.html { redirect_to(controller: 'users', action: params[:user_action], id: @the_user.id) }
        format.xml  { render xml: @the_user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def get_time_zones(default)
    # renvoie la liste des time zone
    lst = User.time_zones
    get_html_options(lst, default, false)
  end

  def show_
    @the_user = User.find(params[:id])
  end
end
