class HelpController < ApplicationController
  access_control (Access.find_for_controller(controller_class_name()))
  layout "help"
  def index
    @help=params[:help]
    respond_to do |format|
      format.html # index.html.erb
      #format.xml  { render :xml => @forums }
    end
  end
  
end
