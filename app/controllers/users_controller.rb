class UsersController < ApplicationController
  access_control(Access.find_for_controller(controller_class_name))

  def update
    @user = User.find(current_user)
    @user.update_attributes(params[:user])
    uri = session[:original_uri]
    session[:original_uri] = nil
    redirect_to(uri || { :controller => "main", :action => "index" })
  end

end