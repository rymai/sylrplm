class MainController < ApplicationController
  include Controllers::PlmInitControllerModule

  access_control(Access.find_for_controller(controller_class_name))
    
  def infos
    request.env["PATH_INFO"] +":"+__FILE__+":"+__LINE__.to_s
  end

  def index
    LOG.info("#{infos} ==>")#KO car num ligne=8 !!
    LOG.error("erreur")
    LOG.warn("attention")
    LOG.debug("debug")
    LOG.fatal("fatal")
    message = check_init
    puts "main_controller.index"
    @datas = get_datas_count
    unless params[:theme].nil?
      @theme = params[:theme]
      unless @current_user.nil?
        puts "main_controller.index:theme=#{params.inspect}"
        @current_user.theme = @theme
        st = @current_user.save
        puts "main_controller.index:theme=#{@theme} update=#{st}"
      else
        session[:theme] = @theme
        puts "main_controller.index:theme=#{session[:theme]}"
      end
    end
    @themes = get_themes(@theme)
    if message == ""
      flash[:notice] = "#{message}</br>#{t(label_theme)}=#{@theme}"
      respond_to do |format|
        format.html # index.html.erb
      end
    end
    LOG.info("<==")
  end

  # appelle si il manque des objets pour demarrer (user, role, types, status)
  def init_objects
    puts "main_controller.init_objects"
    check_init_objects
    @themes = get_themes(@theme)
    create_admin
    unless params[:domain].blank?
      # creation du domaine demande: status et types d'objets
      create_domain(params[:domain])
      update_admin(params[:directory])
      check_init
      st=Access.init
      @domains == nil
      flash[:notice] = t(:ctrl_init_done)
    else
      @domains = get_domains
      flash[:notice] = t(:ctrl_init_to_do)
    end
    @directory = SYLRPLM::VOLUME_DIRECTORY_DEFAULT
    respond_to do |format|
      format.html # init.html.erb
    end
  end

end