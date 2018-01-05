# frozen_string_literal: true

class HelpController < ApplicationController
  access_control(Access.find_for_controller(controller_name.classify))
  layout 'help'

  def index
    @help = params[:help]
    respond_to do |format|
      format.html # index.html.erb
    end
  end
end
