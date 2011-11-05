class SessionsController < ApplicationController

  skip_before_filter :authorize, :object_exists, :check_user
  def new
    puts "sessions_controller.new"+params.inspect
  end

  def edit
    puts "sessions_controller.edit"+params.inspect
  end

  def create
    puts "sessions_controller.create"+params.inspect
    flash.now[:notice] = "post" 
    if current_user.nil?
      cur_user = User.authenticate(params["login"], params["password"])
      respond_to do |format|
        if cur_user
          @roles = cur_user.roles
          @groups= cur_user.groups
          @projects = cur_user.projects
          if @roles.count > 0 && @groups.count > 0 && @projects.count > 0
            @current_user = cur_user
            session[:user_id] = cur_user.id
            flash[:notice]    = t(:ctrl_role_needed)
            format.html { render :action => "edit" }
          else
            @current_user=nil
            session[:user_id] = nil
            flash[:notice] =""
            flash[:notice] += t(:ctrl_user_without_roles) unless @roles.count>0
            flash[:notice] += ", "+t(:ctrl_user_without_groups) unless @groups.count>0
            flash[:notice] += ", "+t(:ctrl_user_without_projects) unless @projects.count>0
            puts "sessions_controller.create:"+flash[:notice]
            format.html { render :new }
            format.xml  {render :xml => errs, :status => :unprocessable_entity }
          end
        else
          @current_user=nil
          session[:user_id] = nil
          flash[:notice] =t(:ctrl_invalid_login)
          format.html { render :new }
          format.xml  { render :xml => errs, :status => :unprocessable_entity }
        end
      end
    else
      respond_to do |format|
        if @current_user.update_attributes(params[:session])
          session[:user_id] = @current_user.id
          uri=session[:original_uri]
          session[:original_uri]=nil
          flash[:notice] = t(:ctrl_user_connected, :user => current_user.login)
          format.html { redirect_to_main(uri) }
          format.xml  { head :ok }
        else
          errs=@current_user.errors
          flash[:notice] = t(:ctrl_user_not_connected, :user => @current_user.login)
          @current_user=nil
          session[:user_id] = nil
          format.html { render :new }
          format.xml  { render :xml => errs, :status => :unprocessable_entity }
        end
      end
    end
    
  end

  def update
    puts "sessions_controller.update"+params.inspect
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