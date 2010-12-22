class SessionsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  skip_before_filter :authorize, :only => [:new, :create]
  access_control(Access.find_for_controller(controller_class_name))

  def index
  end

  def new
  end

  def create
    flash.now[:notice] = "post"
    @user = User.authenticate(params[:login], params[:password])
    respond_to do |format|
      if @user
        session[:user_id] = @user.id
        flash[:notice]    = t(:ctrl_role_needed)
        format.html { redirect_to choose_role_sessions_url }
      else
        flash[:notice] = t(:ctrl_invalid_login)
        format.html { render :new }
      end
    end
  end

  def choose_role
    @roles = current_user.roles
    # @user = User.find_user(session)
    # @user.update_attributes(params[:user])
    # uri = session[:original_uri]
    # session[:original_uri] = nil
    # redirect_to(uri || { :controller => "main", :action => "index" })
  end

  # # just display the form and wait for user to
  # # enter a name and password
  # def login
  #   if request.post?
  #   else
  #     flash.now[:notice] = t(:ctrl_user_needed)
  #     @roles = nil
  #     session[:user_id] = nil
  #   end
  # end

  def add_user
    @user    = User.create_new(params[:user])
    @roles   = Role.all
    @themes  = get_themes(@theme)
    @volumes = Volume.find_all
    if request.post?
      puts "login_controller.add_user:#{@user.inspect}"
      if @user.save
        flash.now[:notice] = t(:ctrl_user_created, :user => @user.login)
        unless params[:role_id].nil?
          @roles.each do |rid|
            role = Role.find(rid)
            if params[:role_id][role.id.to_s] == "1"
              if @user.roles.count(:all, :conditions => { :id => rid.id }) == 0
                flash[:notice] += "<br />" + t(:ctrl_user_role, :role => role.title)
                @user.roles << role
              end
            end
          end
        end
      else
        flash.now[:notice] = t(:ctrl_user_not_created, :user => @user.login)
      end
    end
  end

  def edit_user
    puts "login_controller.edit_user"
    id       = params[:id]
    @user    = User.find(id)
    @volumes = Volume.find_all
    @roles   = Role.all
    if request.post?
      if @user.update_attributes(params[:user])
        flash[:notice] = t(:ctrl_user_updated, :user => @user.login)
        unless params[:role_id].nil?
          @roles.each do |rid|
            role = Role.find(rid)
            if params[:role_id][role.id.to_s] == "1"
              if @user.roles.count(:all, :conditions => { :id => rid.id }) == 0
                flash[:notice] += " #{role.id}:#{role.title}:#{params[:role_id][role.id]}"
                @user.roles << role
              end
            end
          end
        end
      else
        flash.now[:notice] = t(:ctrl_user_not_updated, :user => @user.login)
      end
    end
    @themes = get_themes(@theme)
  end

  def delete_user
    id = params[:id]
    if id && user = User.find(id)
      if id != session[:user_id]
        begin
          user.destroy
          flash[:notice] = t(:ctrl_user_deleted, :user => @user.login)
        rescue Exception => e
          flash[:notice] = e.message
        end
      else
        flash[:notice] = t(:ctrl_user_connected, :user => @user.login)
      end
    end
    redirect_to(:action => :list_users)
  end

  def list_users
    @all_users = User.find_paginate({ :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = t(:ctrl_user_disconnected, :user => @user.login) if @user != :user_not_connected
    redirect_to(:controller => "main", :action => "index")
  end

end