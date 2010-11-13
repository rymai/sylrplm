class MainController < ApplicationController
  include PlmInitControllerModule
  
  
  access_control (Access.findForController(controller_class_name()))
  
  def infos()
    request.env["PATH_INFO"] +":"+__FILE__+":"+__LINE__.to_s
  end

  def index
    @logger.info(infos+"==>")#KO car num ligne=8 !!
    @logger.error("erreur")
    @logger.warn("attention")
    @logger.debug("debug")
    @logger.fatal("fatal")
    message=check_init
    puts "main_controller.index"
    if(params[:theme]!=nil)
      @theme=params[:theme]
      if(@user!=t(:user_not_connected))
        puts "main_controller.index:theme="+params.inspect
        @user.theme=@theme
        st=@user.save
        puts "main_controller.index:theme="+@theme+" update="+st.to_s
      else
        session[:theme]=@theme
        puts "main_controller.index:theme="+session[:theme]
      end
    end
    @themes=get_themes(@theme)
    if message=="" 
      flash[:notice]=message+"</br>"+t(label_theme)+"="+@theme
      respond_to do |format|
        format.html # index.html.erb
      end
    end
    @logger.info("<==")
  end
  
  # appelle si il manque des objets pour demarrer (user, role, types, status)
  def init_objects
    check_init_objects
    @themes=get_themes(@theme)
    puts "main_controller.init_objects"
    if params[:domain] !=nil && params[:domain] != ""
      # creation du domaine demande: status et types d'objets
      create_domain(params[:domain])
      create_volume(params[:directory])
      check_init
      @domains==nil
      flash[:notice]=t(:ctrl_init_done)
    else
      @domains=get_domains
      flash[:notice]=t(:ctrl_init_to_do)
    end
    @directory=SYLRPLM::VOLUME_DIRECTORY_DEFAULT
    respond_to do |format|
      format.html # init.html.erb
    end
  end
  
end
