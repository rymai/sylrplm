class LoginController < ApplicationController
  include Controllers::PlmObjectControllerModule
  before_filter :authorize, :except => [:login, :logout]
  access_control (Access.find_for_controller(controller_class_name()))
  
  def index
    @total_documents = Document.count
    @total_parts = Part.count
    @total_projects = Project.count
    @total_customers = Customer.count
    #@total_favoris = Favori.count
  end
  
  # just display the form and wait for user to
  # enter a name and password
  
  def login     
    if request.post?
      flash.now[:notice] = "post"
      if(session[:user_id]==nil)
        @user = User.authenticate(params[:login], params[:password])
        if @user
          @roles=@user.roles
          session[:user_id] = @user.id
          flash.now[:notice] = t(:ctrl_role_needed)
        else
          flash.now[:notice] = t(:ctrl_invalid_login)
        end
      else
        @user=User.find_user(session)
        @user.update_attributes(params[:user])    
        uri=session[:original_uri]
        session[:original_uri]=nil
        redirect_to(uri || {:controller => "main", :action => "index"})
      end
    else
      flash.now[:notice] = t(:ctrl_user_needed)
      @roles=nil
      session[:user_id] = nil
    end
  end
  
  def add_user
    @user = User.create_new(params[:user])
    @roles = Role.all
    @themes=get_themes(@theme)
    @volumes = Volume.find_all 
    if request.post? 
      puts "login_controller.add_user:"+@user.inspect
      if @user.save   
        #@theme=params[:theme]
        
        #@user.theme=@theme
        #@user.save
        flash.now[:notice] = t(:ctrl_user_created,:user=>@user.login)
        #@user = User.new
        if params[:role_id]!=nil  
          @roles.each do |rid|
            role=Role.find(rid)
            if(params[:role_id][role.id.to_s]=="1")
              if(@user.roles.count(:all, :conditions=>["id=#{rid.id}"])==0)
                flash[:notice]+="<br/>"+t(:ctrl_user_role,:role=>role.title)           
                @user.roles<<role                                
              end
            end
          end
        end 
      else
        flash.now[:notice] = t(:ctrl_user_not_created,:user=>@user.login)
      end
    end
  end
  
  def edit_user
    puts "login_controller.edit_user"
    #@roles=@user.roles
    #respond_to do |format|
    id = params[:id]
    @user = User.find(id) 
    @volumes = Volume.find_all 
    @roles = Role.all
    if request.post?
      if @user.update_attributes(params[:user])
        flash[:notice] = t(:ctrl_user_updated,:user=>@user.login)
        #@theme=params[:theme]
        #puts "login_controller.edit_user avec theme:"+params.inspect
        #@user.theme=@theme
        #@user.save
        if params[:role_id]!=nil  
          @roles.each do |rid|
            role=Role.find(rid)
            if(params[:role_id][role.id.to_s]=="1")
              if(@user.roles.count(:all, :conditions=>["id=#{rid.id}"])==0)
                flash[:notice]+=" #{role.id}:#{role.title}:#{params[:role_id][role.id.to_s]}"              
                @user.roles<<role                                
              end
            end
          end
        end 
            #format.html { redirect_to(@login) }
            #format.xml  { head :ok }
     else
            flash.now[:notice] = t(:ctrl_user_not_updated,:user=>@user.login)
            #format.html { render :action => "edit" }
            #format.xml  { render :xml => @login.errors, :status => :unprocessable_entity }
     end
       # end
   end
   @themes=get_themes(@theme)
  end
  
  def delete_user
   id = params[:id]
    if id && user = User.find(id)
    
      if(id!=session[:user_id])
      begin
        user.destroy
        flash[:notice] = t(:ctrl_user_deleted,:user=>@user.login)
      rescue Exception => e
        flash[:notice] = e.message
      end
      else
        flash[:notice] = t(:ctrl_user_connected,:user=>@user.login)
      end
    end
    redirect_to(:action => :list_users)
  end

  def list_users
   #@all_users = User.find(:all)
    @all_users = User.find_paginate({:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})   
  end

  def logout
   session[:user_id] = nil
   if @user!=:user_not_connected
    flash[:notice] = t(:ctrl_user_disconnected,:user=>@user.login)
    end
    redirect_to(:controller => "main", :action => "index")
  end
  
      
end
