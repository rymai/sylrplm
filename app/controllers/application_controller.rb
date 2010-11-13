# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

#  controleur principal.
class ApplicationController < ActionController::Base
  require 'rexml/document'
  
  require 'logger'
  
  #include REXML
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  before_filter :authorize, :except => [:index,:init_objects,:get_themes,:find_theme,:permission_denied,:permission_granted,
  :permission_granted,:current_user,:redirect_to_index,:tree_part,:tree_project,:tree_customer,:follow_tree_part,:follow_tree_up_part,
  :follow_tree_project,:follow_tree_up_project,:follow_tree_customer,:tree_documents,:tree_forums] 
  before_filter :set_locale 
  before_filter :define_variables
  
  access_control (Access.findForController(controller_class_name()))
  
  def permission_denied
    flash[:notice] = t(:ctrl_no_privilege)
    return redirect_to(:action => "index") 
  end
  
  def permission_granted
    #flash[:notice] = "Welcome to the secure area !"
  end  
  
  class Class
    def extend?(klass)
      not superclass.nil? and ( superclass == klass or superclass.extend? klass )
    end
  end
  
  def getModelsAndColumns
    ret=""
    i=0
    models = Dir.new("#{RAILS_ROOT}/app/models").entries
    models.each do |model|
      if model != "." && model != ".." && model.index('obsolete')==nil
        mdl = model.camelize.gsub(".rb","")
        #puts 'ApplicationController.getModels:mdl='+mdl
        omdl = eval(mdl)
        begin
          cols=omdl.content_columns()
        rescue Exception
          #puts 'ApplicationController.getModels:pas ActiveRecord::Base:='+mdl
        else
          #if(met!='index' && met!='login' && met!='logout' && met.index('_old')==nil && met.index('obsolete')==nil)
          cols.each {|col|
            if(col.name != 'created_at' && col.name != 'updated_at' && col.name != 'owner')
              mdlcol=mdl.to_s+"."+col.name
              ret+="<option>"+mdlcol+"</option>"
              #puts 'ApplicationController.getModels:model.col='+mdlcol
            end           
            i=i+1;       
          }
        end   
      end
    end
    return ret
  end
  
  
  # definition de la langue
  def set_locale
    if(params[:locale]!=nil)
      I18n.locale = params[:locale] || 'en ou fr'
      session[:lng]=I18n.locale
    else
      if(session[:lng]!=nil)
        I18n.locale=session[:lng]
      else
        I18n.locale=SYLRPLM::LOCAL_DEFAULT
        session[:lng]=I18n.locale
      end
    end
    #I18n.locale = "en" #force a en sinon les date_select ne marchent plus
    #I18n.load_path += Dir[ File.join(RAILS_ROOT, 'lib', 'locale', '*.{rb,yml}') ]
  end
  
  def current_user
    @current_user ||= session[:user_id] ? User.find(session[:user_id]) : nil
  end
  
  # Build a Logger::Formatter subclass.
  class SylFormatter < Logger::Formatter
    # Provide a call() method that returns the formatted message.
    def call(severity, time, program_name, message)
      datetime      = time.strftime("%Y-%m-%d %H:%M")
      if severity == "ERROR"
        
        print_message = "!!! #{String(message)} (#{datetime}) !!!"
        border        = "!" * print_message.length
        [border, print_message, border].join("\n") + "\n"
      else
        #super
        [severity.ljust(5), datetime, program_name, message].join("_") + "\n"
      end
    end
  end
  
  # definition des variables globales.
  def define_variables
    @user =find_user
    @userid =find_userid
    @username =find_username
    @usermail =find_usermail
    @userrole =find_userrole
    @favori_document=find_favori_document
    @favori_project=find_favori_project
    @favori_part=find_favori_part
    @urlbase="http://"+request.env["HTTP_HOST"]
    @theme=find_theme
    logfile = File.join(File.dirname(__FILE__),'..','..','log', 'sylrplm.log')
    @logger = Logger.new(logfile, 'daily')
    @logger.level     = Logger::DEBUG #DEBUG INFO WARN ERROR FATAL ANY
    @logger.formatter = SylFormatter.new  # Install custom formatter!
    #@logger.datetime_format = "%Y-%m-%d %H:%M:%S"
  end
  
  def get_themes(default)
    #renvoie la liste des themes 
    dirname=RAILS_ROOT + '/public/stylesheets/*'
    ret=""
    Dir.glob(dirname).each do |dir|
      theme=File.basename(dir, '.*')
      if(theme==default)
        ret<<"<option selected=\"selected\">"<<theme<<"</option>"
    else
      ret<<"<option>"<<theme<<"</option>"
      end
    end
    puts "application_controller.get_themes"+dirname+"="+ret
    return ret
  end
  
  #utilise pour les filtres des objets (index)
  def qry_type
    "typesobject_id in(select id from typesobjects as t where t.name LIKE ?)"
  end
  def qry_status
    "statusobject_id in (select id from statusobjects as s where s.name LIKE ?)"
  end
  def qry_owner
    "owner in(select id from users where login LIKE ?)"
  end
  def qry_volume
    "volume_id in(select id from volumes where name LIKE ?)"
  end
  
  
  # nombre d'objets listes par page si pagination
  def cfg_items_per_page
    SYLRPLM::NB_ITEMS_PER_PAGE
  end
  
  # recherche du theme
  def find_theme
    ret=SYLRPLM::THEME_DEFAULT 
    if session[:user_id]
      if user = User.find(session[:user_id])
        if(user.theme!=nil)
          ret=user.theme
        end
      end
    else
      if session[:theme]
        ret=session[:theme]
      end
    end
  return ret
  end
  
  # recherche du user connecte
  def find_user
    if session[:user_id] 
      if  user = User.find(session[:user_id])
        user
      else 
              t(:user_not_connected)
      end
    else
          t(:user_not_connected)
    end
  end
  
  # recherche de l'id du user connecte
  def find_userid
    if session[:user_id] 
      if  user = User.find(session[:user_id])
        user.id
      else 
        nil
      end
    else
      nil
    end
  end
  
  # recherche du nom du user connecte      
  def find_username
    if session[:user_id] 
      if user = User.find(session[:user_id])
        user.login
      else 
            t(:user_unknown)
      end
    else
        t(:user_not_connected)
    end
  end
  
  # recherche du role du user connecte
  def find_userrole
    if session[:user_id] 
      if  user = User.find(session[:user_id])
        if(user.role != nil) 
          user.role.title
        else
                  ""
        end
      else 
              ""
      end
    else
          ""
    end
  end
  
  # recherche du mail du user connecte
  def find_usermail
    if session[:user_id] 
      if  user = User.find(session[:user_id])
        if(user.email != nil) 
          user.email
        else
             t(:user_unknown_mail)
        end
      else 
          t(:user_unknown_mail)
      end
    else
      t(:user_unknown_mail)
    end
  end
  
  # recherche du favori des documents
  def find_favori_document
    session[:favori_document] ||= FavoriDocument.new
  end
  
  # recherche du favori des projets
  def find_favori_project
    session[:favori_project] ||= FavoriProject.new
  end
  
  # recherche du favori des parts
  def find_favori_part
    session[:favori_part] ||= FavoriPart.new
  end
  
  def reset_favori_document
    session[:favori_document]=nil    
  end
  def reset_favori_part
    session[:favori_part]=nil    
  end
  def reset_favori_project
    session[:favori_project]=nil    
  end
  
  # redirection vers l'action index
  def redirect_to_index(msg=nil)
    flash[:notice]=msg if msg
    redirect_to :action => index 
    return
  end
  
  
  
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  private 
  def authorize
    unless User.find_by_id(session[:user_id])
      session[:original_uri] = request.request_uri
      flash[:notice] =t(:login_login)
      redirect_to(:controller => "login", :action=> "login")
    end    
  end
  

    
  
   
end
