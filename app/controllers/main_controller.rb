require 'classes/controller'



class MainController < ApplicationController

  #access_control(Access.find_for_controller(controller_class_name))
  skip_before_filter :authorize
  #def infos
  #  request.env["PATH_INFO"] +":"+__FILE__+":"+__LINE__.to_s
  #end
  def index
    if true
      LOG.info("info")
      LOG.error("erreur")
      LOG.warn("attention")
      LOG.debug("debug")
      LOG.fatal("fatal")
    end
    unless params[:domain].blank?
      # creation du domaine demande: status et types d'objets
      st=Controller.init_db(params)
      flash[:notice] = t(:ctrl_init_done)
    else
      @domains = Controller.get_domains
      @directory = SYLRPLM::VOLUME_DIRECTORY_DEFAULT
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
    end
    respond_to do |format|
      format.html # index.html.erb
    end
    #LOG.info("<==")
  end

end