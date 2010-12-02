# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'rexml/document'
#require 'logger'
require "lib/classes/app_classes"
#  controleur principal.
class ApplicationController < ActionController::Base
  include AppClasses
  #include REXML
  helper :all # include all helpers, all the time
  
  layout "main"
  
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  filter_parameter_logging :password
  before_filter :authorize, :except => [:index,:init_objects,:get_themes,:find_theme,:permission_denied,:permission_granted,
  :permission_granted,:current_user,:redirect_to_index,:tree_part,:tree_project,:tree_customer,:follow_tree_part,:follow_tree_up_part,
  :follow_tree_project,:follow_tree_up_project,:follow_tree_customer,:tree_documents,:tree_forums] 
  before_filter :set_locale 
  before_filter :define_variables
  
  access_control (Access.find_for_controller(controller_class_name()))
  
  def permission_denied
    flash[:notice] = t(:ctrl_no_privilege)
    redirect_to(:action => "index") 
  end
  
  def permission_granted
    #flash[:notice] = "Welcome to the secure area !"
  end  
  
  class Class
    def extend?(klass)
      not superclass.nil? && ( superclass == klass or superclass.extend? klass )
    end
  end
  
  def get_models_and_columns
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
    ret
  end
  
  
  # definition de la langue
  def set_locale
    if params[:locale]
      I18n.locale = params[:locale] 
      session[:lng]=I18n.locale
    else
      if session[:lng]
        I18n.locale = session[:lng]
      else
        I18n.locale=SYLRPLM::LOCAL_DEFAULT
        session[:lng] = I18n.locale
      end
    end
    #I18n.locale = "en" #force a en sinon les date_select ne marchent plus
    #I18n.load_path += Dir[ File.join(RAILS_ROOT, 'lib', 'locale', '*.{rb,yml}') ]
  end
  
  def current_user
    @current_user ||= session[:user_id] ? User.find(session[:user_id]) : nil
  end
  
  
  # definition des variables globales.
  def define_variables
    @user = User.find_user(session)
    @userid = User.find_userid(session)
    @username = User.find_username(session)
    @usermail = User.find_usermail(session)
    @userrole = User.find_userrole(session)
    @favori_document=  find_favori_document
    @favori_project  = find_favori_project
    @favori_part = find_favori_part
    @urlbase="http://"+request.env["HTTP_HOST"]
    @theme=User.find_theme(session)
    logfile = File.join(File.dirname(__FILE__),'..','..','log', 'sylrplm.log')
    @logger = Logger.new(logfile, 'daily')
    @logger.level     = Logger::DEBUG #DEBUG INFO WARN ERROR FATAL ANY
    @logger.formatter = LogFormatter.new  # Install custom formatter!
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
    ret
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
