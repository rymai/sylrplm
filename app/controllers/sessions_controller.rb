class SessionsController < ApplicationController

  skip_before_filter :authorize, :object_exists
  def new
    @languages = get_languages
  end

  def edit
    @roles = current_user.roles
  end

  def create
    flash.now[:notice] = "post"
    if current_user.nil?
      @current_user = User.authenticate(params[:login], params[:password])
      @languages = get_languages
      respond_to do |format|
        if current_user
          @roles = current_user.roles
          if @roles.count>0
            session[:user_id] = current_user.id
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
    else
      respond_to do |format|
        if current_user.update_attributes(params[:sessions])
          puts "sessions_controller.update ok"
          uri=session[:original_uri]
          session[:original_uri]=nil
          flash[:notice] = t(:ctrl_user_connected, :user => current_user.login)
          format.html { redirect_to_main(uri) }
          format.xml  { head :ok }
        else
          puts "sessions_controller.update ko"
          flash.now[:notice] = t(:ctrl_user_not_connected, :user => current_user.login)
          format.html { redirect_to_main(uri) }
          format.xml  { render :xml => current_user.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  

  def destroy
    puts "sessions_controller.destroy:"+params.inspect
    session[:user_id] = nil
    flash[:notice] = t(:ctrl_user_disconnected, :user => current_user.login) if current_user != nil
    #bouclage
    #format.html { redirect_to_main(uri) }
    #format.xml  { head :ok }
    redirect_to(:controller => "main", :action => "index")
  end

end