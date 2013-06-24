require 'classes/controller'



class MainController < ApplicationController

  #access_control(Access.find_for_controller(controller_name))
  skip_before_filter :authorize
  #def infos
  #  request.env["PATH_INFO"] +":"+__FILE__+":"+__LINE__.to_s
  #end
  def index

    unless params[:domain].blank?
      # creation du domaine demande: status et types d'objets
      st=Controller.init_db(params)
      flash[:notice] = t(:ctrl_init_done)
    else
      @domains = Controller.get_domains
      @directory = PlmServices.get_property(:VOLUME_DIRECTORY_DEFAULT)
    end
    @datas = get_datas_count
    @themes = get_themes(@theme)
    unless params[:theme].nil?
      @theme = params[:theme]
      unless @current_user.nil?
      @current_user.theme = @theme
      st = @current_user.save
      else
        session[:theme] = @theme
      end
    end
    unless params[:locale].nil?
      set_locale
      unless @current_user.nil?
      @current_user.language = params[:locale]
      st = @current_user.save
      end
    end
    unless params[:domain].nil?
      set_domain
    end
    respond_to do |format|
      format.html # index.html.erb
    end

  end

 def helpgeneral
		puts " helpgeneral"
		respond_to do |format|
			format.html # helpgeneral.html.erb
		end
	end

end
