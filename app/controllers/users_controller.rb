class UsersController < ApplicationController
  include Controllers::PlmObjectControllerModule
  access_control(Access.find_for_controller(controller_class_name))
  #
  # Used by is_admin?
  #
  ADMIN_GROUP_NAME = SYLRPLM::ADMIN_GROUP_NAME
  # GET /users
  # GET /users.xml
  def index
    @current_users = User.find_paginate({:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @current_users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @the_user = User.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @the_user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @the_user = User.create_new
    @roles   = Role.all
    @themes  = get_themes(@theme)
    @languages=get_languages(@language)
    @notifications=get_notifications(@notification)
    @time_zones=get_time_zones(@time_zone)
    @volumes = Volume.find_all
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @the_user }
    end
  end

  # GET /users/1/edit
  def edit
    @the_user = User.find(params[:id])
    @roles   = Role.all
    @themes  = get_themes(@theme)
    @languages = get_languages
    @notifications = get_notifications(@the_user.notification)
    @time_zones = get_time_zones(@the_user.time_zone)
    @volumes = Volume.find_all
  end

  def create
    @the_user    = User.new(params[:user])
    @roles   = Role.all
    @themes  = get_themes(@theme)
    @volumes = Volume.find_all
    puts "users_controller.create:#{@the_user.inspect}"
    respond_to do |format|
      if @@the_user.save
        unless params[:role_id].nil?
          flash[:notice]=""
          @roles.each do |rid|
            role = Role.find(rid)
            if params[:role_id][role.id.to_s] == "1"
              if @@the_user.roles.count(:all, :conditions => { :id => rid.id }) == 0
                flash[:notice] += "<br />" + t(:ctrl_user_role, :role => role.title)
                @@the_user.roles << role
              end
            end
          end
        end
        flash.now[:notice] = t(:ctrl_user_created, :user => @the_user.login)
        format.html { redirect_to(@the_user) }
        format.xml  { render :xml => @the_user, :status => :created, :location => @the_user }
      else
        flash.now[:notice] = t(:ctrl_user_not_created, :user => @the_user.login)
        format.html { render :action => "new" }
        format.xml  { render :xml => @the_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    puts "users_controller.update:params="+params.inspect
    @the_user    = User.find(params[:id])
    @volumes = Volume.find_all
    @roles   = Role.all
    @themes = get_themes(@theme)
    @languages = get_languages
    @notifications = get_notifications(@the_user.notification)
    @time_zones = get_time_zones(@the_user.time_zone)
    respond_to do |format|
      if @the_user.update_attributes(params[:user])
        #puts "users_controller.update:roles="+params[:role_id].inspect
        unless params[:role_id].nil?
          flash[:notice] =""
          @roles.each do |rid|
            role = Role.find(rid)
            if params[:role_id][role.id.to_s] == "1"
              if @the_user.roles.count(:all, :conditions => { :id => rid.id }) == 0
                flash[:notice] += " #{role.id}:#{role.title}:#{params[:role_id][role.id]}"
                @the_user.roles << role
              end
            end
          end
        end
        flash[:notice] = t(:ctrl_user_updated, :user => @the_user.login)
        format.html { redirect_to(@the_user) }
        format.xml  { head :ok }
      else
        flash.now[:notice] = t(:ctrl_user_not_updated, :user => @the_user.login)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @the_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    id = params[:id]
    if id && @the_user = User.find(id)
      if id != session[:user_id]
        begin
          @the_user.destroy
          flash[:notice] = t(:ctrl_user_deleted, :user => @the_user.login)
        rescue Exception => e
          flash[:notice] = e.message
        end
      else
        flash[:notice] = t(:ctrl_user_connected, :user => @the_user.login)
      end
    end
    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end

  def get_notifications(default)
    #renvoie la liste des notifications
    lst=User.notifications
    get_html_options(lst,default,true)
  end

  def get_time_zones(default)
    #renvoie la liste des time zone
    lst=User.time_zones
    get_html_options(lst,default,false)
  end

end
