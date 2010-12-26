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
  
  def destroy
    session[:user_id] = nil
    flash[:notice] = t(:ctrl_user_disconnected, :user => @user.login) if @user != :user_not_connected
    redirect_to(:controller => "main", :action => "index")
  end

end