class SessionsController < ApplicationController
  #include Controllers::PlmObjectControllerModule

  skip_before_filter :authorize
  #access_control(Access.find_for_controller(controller_class_name))
  
  def index
    puts "sessions_controller.index"+params.inspect
  end

  def new
    puts "sessions_controller.new"+params.inspect
  end

  def edit
    @roles = @current_user.roles
  end

  def create
    puts "sessions_controller.create:"+params.inspect
    flash.now[:notice] = "post"
    @current_user = User.authenticate(params[:login], params[:password])
    respond_to do |format|
      if @current_user
        #format.html { redirect_to choose_role_sessions_url }
        @roles = @current_user.roles
        if @roles.count>0
          session[:user_id] = @current_user.id
          flash[:notice]    = t(:ctrl_role_needed)
          format.html { render :action => "edit" }
        else
          @current_user=nil
          flash[:notice] = t(:ctrl_user_without_roles)
          format.html { render :new }
        end
      else
        flash[:notice] = t(:ctrl_invalid_login)
        format.html { render :new }
      end
    end
  end

  def choose_role
    puts "sessions_controller.choose_role:"+params.inspect
    @roles = @current_user.roles
    # @current_user = User.find_user(session)
    # @current_user.update_attributes(params[:user])
    # uri = session[:original_uri]
    # session[:original_uri] = nil
    # redirect_to(uri || { :controller => "main", :action => "index" })
  end

  #appelle par choose_role
  def update
    puts "sessions_controller.update:"+params.inspect
    @current_user    = User.find(params[:id])
    respond_to do |format|
      if @current_user.update_attributes(params[:sessions])
        puts "sessions_controller.update ok"
        uri=session[:original_uri]
        session[:original_uri]=nil
        flash[:notice] = t(:ctrl_user_connected, :user => @current_user.login)
        format.html { redirect_to_main(uri) }
        format.xml  { head :ok }
      else
        puts "sessions_controller.update ko"
        flash.now[:notice] = t(:ctrl_user_not_connected, :user => @current_username)
        format.html { redirect_to_main(uri) }
        format.xml  { render :xml => @current_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    puts "sessions_controller.destroy:"+params.inspect
    session[:user_id] = nil
    flash[:notice] = t(:ctrl_user_disconnected, :user => @current_username) if @current_user != nil
    redirect_to(:controller => "main", :action => "index")
  end

end