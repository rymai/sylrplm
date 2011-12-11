require 'controllers/plm_object_controller_module'

class ErrorReply < Exception
  attr_reader :status
  def initialize (msg, status=400)
    super(msg)
    @status = status
  end
end

class ApplicationController < ActionController::Base
  include Controllers::PlmObjectControllerModule
  
  helper :all  # include all helpers, all the time
  helper_method :current_user, :logged_in?, :admin_logged_in?
  
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  filter_parameter_logging :password
  
  before_filter :authorize, :except => [:index, :init_objects]
  before_filter :set_locale
  before_filter :define_variables

  ## un peu brutal before_filter :object_exists, :only => [:show, :edit, :destroy]
  #
  def update_accessor(obj)
    mdl_name = obj.model_name
    params[mdl_name][:owner_id]=current_user.id if obj.instance_variable_defined?(:owner_id)
    params[mdl_name][:group_id]=current_user.group_id if obj.instance_variable_defined?(:group_id)
    params[mdl_name][:projowner_id]=current_user.project_id if obj.instance_variable_defined?(:projowner_id)
    puts "update_accessor:"+params.inspect
  end
  
  def check_user
    if current_user.role.nil? || current_user.group.nil? || current_user.project.nil?
      flash[:notice] = t(:ctrl_user_not_complete )
      redirect_to(:action => "index")
    end
  end
  
  def event
    event_manager
  end

  def permission_denied(role, controller, action)
    flash[:notice] = t(:ctrl_no_privilege, :role=>role, :controller=>controller, :action=>action)
    redirect_to(:action => "index")
  end

  def permission_granted
    #flash[:notice] = "Welcome to the secure area !"
  end

  def render_text(msg)
    flash[:notice] = msg
  end

  class Class
    def extend?(klass)
      !(superclass.nil? && (superclass == klass || superclass.extend?(klass)))
    end
  end

  # definition de la langue
  def set_locale
    @current_user             = User.find_user(session)
    if params[:locale]
      I18n.locale = params[:locale]
      session[:lng] = I18n.locale
    else
      unless @current_user.nil?
        I18n.locale = @current_user.language
      else
        if session[:lng]
          I18n.locale = session[:lng]
        else
          I18n.locale = SYLRPLM::LOCAL_DEFAULT
          session[:lng] = I18n.locale
        end
      end
    end
  end

  # definition des variables globales.
  def define_variables
    @favori      = session[:favori] ||= Favori.new
    @urlbase          = "http://"+request.env["HTTP_HOST"]
    @theme            = User.find_theme(session)
    @themes = get_themes(@theme)
    @language=SYLRPLM::LOCAL_DEFAULT
    @languages = get_languages
    @notification=SYLRPLM::NOTIFICATION_DEFAULT
    @time_zone=SYLRPLM::TIME_ZONE_DEFAULT
    # mise n forme d'une tache (workitem)
    @payload_partial = 'shared/ruote_forms'

    WillPaginate::ViewHelpers.pagination_options[:previous_label] = t('label_previous')
    WillPaginate::ViewHelpers.pagination_options[:next_label] = t('label_next')
    WillPaginate::ViewHelpers.pagination_options[:page_links ] = true  # when false, only previous/next links are rendered (default: true)
    WillPaginate::ViewHelpers.pagination_options[:inner_window] = 10 # how many links are shown around the current page (default: 4)
    WillPaginate::ViewHelpers.pagination_options[:page_links ] = true  # when false, only previous/next links are rendered (default: true)
    WillPaginate::ViewHelpers.pagination_options[:inner_window] = 10 # how many links are shown around the current page (default: 4)
    WillPaginate::ViewHelpers.pagination_options[:outer_window] = 3 # how many links are around the first and the last page (default: 1)
    WillPaginate::ViewHelpers.pagination_options[:separator ] = ' - '   # string separator for page HTML elements (default: single space)

    LOG.info("__FILE__")
  end


  # nombre d'objets listes par page si pagination
  def cfg_items_per_page
    SYLRPLM::NB_ITEMS_PER_PAGE
  end

  # redirection vers l'action index
  def redirect_to_index(msg=nil)
    flash[:notice] = msg if msg
    redirect_to :action => index
  end

  # redirection vers l'action index du main si besoin
  def redirect_to_main(uri, msg=nil)
    flash[:notice] = msg if msg
    redirect_to(uri || { :controller => "main", :action => "index" })
  end

  def get_datas_count
    {
      :datafile => Datafile.count,
      :document => Document.count,
      :part => Part.count,
      :project => Project.count,
      :customer => Customer.count,
      :forum => Forum.count,
      :question => Question.count,
      :link => Link.count,
      :user => User.count,
      :role => Role.count,
      :group => Group.count,
      :volume => Volume.count,
      :definition => Definition.count
    }
  end

  def error_reply (error_message, status=400)
    if error_message.is_a?(ErrorReply)
    status = error_message.status
    error_message = error_message.message
    end

    flash[:error] = error_message

    plain_reply = lambda() {
      render(
      :text => error_message,
      :status => status,
      :content_type => 'text/plain')
    }

    respond_to do |format|
      format.html { redirect_to '/' }
      format.json &plain_reply
      format.xml &plain_reply
    end
  end

  rescue_from(ErrorReply) { |e| error_reply(e) }

  #
  # Returns a new LinkGenerator wrapping the current request.
  #
  def linkgen
    LinkGenerator.new(request)
  end

  #
  # Creates an HistoryEntry record
  #
  def history_log (event, options={})
    source = options.delete(:source) || @current_user.login
    OpenWFE::Extras::HistoryEntry.log!(source, event, options)
  end

  def authorize
    user_id = session[:user_id] || User.find_by_id(session[:user_id])
    if user_id.nil? 
      puts "application_controller.authorize.request_uri="+request.request_uri
      puts "application_controller.authorize.new_sessions_url="+new_sessions_url
      session[:original_uri] = request.request_uri
      flash[:notice] = t(:login_login)
      redirect_to new_sessions_url
    else
      user=User.find(user_id)
      unless user.is_admin? 
        if user.roles.nil? || user.volume.nil? || user.groups.nil? || user.projects.nil?
          session[:original_uri] = request.request_uri
          flash[:notice] = t(:login_login)
          redirect_to new_sessions_url
        end
      end
    end
  end

  def current_user
    ret=@current_user ||= User.find_user(session)
    ret
  end

  def logged_in?
    current_user != nil
  end

  # Returns true if the user is connected and having the admin role
  def admin_logged_in?
    ret=false
    if logged_in?
      #puts "admin_connected: connected is_admin="+@current_user.is_admin?.to_s
      if current_user.is_admin?
        ret=true if current_user.is_admin?
      end
    end
    ret
  end
end

