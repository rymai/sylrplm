class SessionsController < ApplicationController

  skip_before_filter :authorize, :object_exists, :check_user
  def new
    #puts "sessions_controller.new"+params.inspect
  end

  def edit
    #puts "sessions_controller.edit"+params.inspect
  end

  def create
    #puts "sessions_controller.create"+params.inspect
    flash.now[:notice] = "post"
    if current_user.nil?
      cur_user = User.authenticate(params["login"], params["password"])
      respond_to do |format|
        if cur_user
           if cur_user.roles.count > 0 && cur_user.groups.count > 0 && cur_user.projects.count > 0
            @current_user = cur_user
            session[:user_id] = cur_user.id
            flash[:notice]    = t(:ctrl_role_needed)
            format.html { render :action => "edit" }
          else
            flash[:notice] =""
            flash[:notice] += t(:ctrl_user_without_roles) unless cur_user.roles.count>0
            flash[:notice] += ", "+t(:ctrl_user_without_groups) unless cur_user.groups.count>0
            flash[:notice] += ", "+t(:ctrl_user_without_projects) unless cur_user.projects.count>0
            @current_user=nil
            session[:user_id] = nil
            format.html { render :new }
            format.xml  {render :xml => errs, :status => :unprocessable_entity }
          end
        else
        # nouvel utilisateur potentiel
          if params["login"].empty? || params["password"].empty?
            @current_user=nil
            session[:user_id] = nil
            flash[:notice] =t(:ctrl_invalid_login)
            format.html { render :new }
            format.xml  { render :xml => errs, :status => :unprocessable_entity }
          else
          # username et password saisis: nouvel utilisateur
            params.delete("authenticity_token")
            params.delete("commit")
            params.delete("controller")
            params.delete("action")
            params["volume_id"]=1
            group_consultants=Group.find_by_name("consultants")
            role_consultant=Role.find_by_title("consultant")
            proj=Project.find_by_ident("PROJET")
            params["group_id"]=group_consultants.id
            params["role_id"]=role_consultant.id
            params["project_id"]=proj.id
            cur_user=User.create_new(params)
            if cur_user.save
              cur_user.groups<<group_consultants
              cur_user.roles<<role_consultant
              relation = Relation.by_types(proj.model_name, cur_user.model_name, proj.typesobject.id, cur_user.typesobject.id)
              link = Link.create_new(proj, cur_user, relation, cur_user)
              link[:link].save
              if cur_user.roles.count > 0 && cur_user.groups.count > 0 && cur_user.projects.count > 0
                @current_user = cur_user
                session[:user_id] = cur_user.id
                flash[:notice]    = t(:ctrl_role_needed)
                format.html { render :action => "edit" }
              else    
                flash[:notice] =""
                flash[:notice] += t(:ctrl_user_without_roles) unless cur_user.roles.count>0
                flash[:notice] += ", "+t(:ctrl_user_without_groups) unless cur_user.groups.count>0
                flash[:notice] += ", "+t(:ctrl_user_without_projects) unless cur_user.projects.count>0
                @current_user=nil
                session[:user_id] = nil
                format.html { render :new }
                format.xml  {render :xml => errs, :status => :unprocessable_entity }
              end
            end
          end
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
    #puts "sessions_controller.update"+params.inspect
  end

  def destroy
    #puts "sessions_controller.destroy:"+params.inspect
    session[:user_id] = nil
    flash[:notice] = t(:ctrl_user_disconnected, :user => current_user.login) if current_user != nil
    #bouclage
    #format.html { redirect_to_main(uri) }
    #format.xml  { head :ok }
    redirect_to(:controller => "main", :action => "index")
  end

end