class UsersController < ApplicationController
  include Controllers::PlmObjectControllerModule
  access_control(Access.find_for_controller(controller_class_name))
  
  # GET /users
  # GET /users.xml
  def index
    @users = User.find_paginate({:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])}) 
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end
  
  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end
  
  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.create_new
    @roles   = Role.all
    @themes  = get_themes(@theme)
    @volumes = Volume.find_all
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end
  
  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
    @roles   = Role.all
    @themes  = get_themes(@theme)
    @volumes = Volume.find_all
  end
  
  def create
    @user    = User.new(params[:user])
    @roles   = Role.all
    @themes  = get_themes(@theme)
    @volumes = Volume.find_all
    puts "users_controller.create:#{@user.inspect}"
    respond_to do |format|
      if @user.save
        unless params[:role_id].nil?
          flash[:notice]=""
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
        flash.now[:notice] = t(:ctrl_user_created, :user => @user.login)
        format.html { redirect_to(@user) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        flash.now[:notice] = t(:ctrl_user_not_created, :user => @user.login)
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    @user    = User.find(params[:id])
    @volumes = Volume.find_all
    @roles   = Role.all
    @themes = get_themes(@theme)
    respond_to do |format|
      if @user.update_attributes(params[:user]) 
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
        flash[:notice] = t(:ctrl_user_updated, :user => @user.login)
        format.html { redirect_to(@user) }
        format.xml  { head :ok }
      else
        flash.now[:notice] = t(:ctrl_user_not_updated, :user => @user.login)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end   
    end
  end
  
  
  def destroy
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
    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end
  
end
