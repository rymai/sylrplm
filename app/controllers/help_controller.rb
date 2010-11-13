class HelpController < ApplicationController
  access_control (Access.findForController(controller_class_name()))
  
  def index
    @help=params[:help]
    respond_to do |format|
      format.html # index.html.erb
      #format.xml  { render :xml => @forums }
    end
  end

end
