class MainController < ApplicationController
  include Controllers::PlmInitControllerModule

  #access_control(Access.find_for_controller(controller_class_name))
  skip_before_filter :authorize
  #def infos
  #  request.env["PATH_INFO"] +":"+__FILE__+":"+__LINE__.to_s
  #end
  def index
    LOG.info("info")
    LOG.error("erreur")
    LOG.warn("attention")
    LOG.debug("debug")
    LOG.fatal("fatal")
    unless params[:domain].blank?
      # creation du domaine demande: status et types d'objets
      create_admin
      create_domain(params[:domain])
      update_admin(params[:directory])
      st=Access.init
      flash[:notice] = t(:ctrl_init_done)
    else
      @domains = get_domains
      @directory = SYLRPLM::VOLUME_DIRECTORY_DEFAULT
      #flash[:notice] = t(:ctrl_init_to_do)
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
    LOG.info("<==")
  end

end