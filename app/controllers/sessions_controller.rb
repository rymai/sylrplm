class SessionsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  skip_before_filter :authorize #, :only => [:index, :edit, :new, :create]
  access_control(Access.find_for_controller(controller_class_name))
  
  def index
#    puts "sessions_controller.index"
#    respond_to do |format|
#      flash[:notice] = "sessions"
#      format.html { render :new }
#    end
#    
  end
  
  def new
  end
  
  def edit
     @roles = current_user.roles
  end
  
  def create
    puts "sessions_controller.create:"+params.inspect
    flash.now[:notice] = "post"
    @user = User.authenticate(params[:login], params[:password])
    respond_to do |format|
      if @user
        session[:user_id] = @user.id
        flash[:notice]    = t(:ctrl_role_needed)
        #format.html { redirect_to choose_role_sessions_url }
         @roles = current_user.roles
         format.html { render :action => "edit" }
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
  
  #appelle par choose_role
  def update
    @user    = User.find(params[:id])
    respond_to do |format|
      if @user.update_attributes(params[:sessions]) 
        puts "sessions_controller.update ok"
        original_uri=session[:original_uri]
        session[:original_uri]=nil
        flash[:notice] = t(:ctrl_user_connected, :user => @user.login)
        format.html { redirect_to(original_uri) }
        format.xml  { head :ok }
      else
        puts "sessions_controller.update ko"
        flash.now[:notice] = t(:ctrl_user_not_connected, :user => @user.login)
        format.html { redirect_to(index_main) }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end   
    end
  end
  
  
  def destroy
    session[:user_id] = nil
    flash[:notice] = t(:ctrl_user_disconnected, :user => @user.login) if @user != :user_not_connected
    redirect_to(:controller => "main", :action => "index")
  end
  
end