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
  ####filter_parameter_logging :password
  before_filter :authorize, :except => [:index, :init_objects]
  before_filter :set_locale
  before_filter :define_variables
  ## un peu brutal before_filter :object_exists, :only => [:show, :edit, :destroy]
  #
  #access_control(Access.find_for_controller(controller_class_name))
  #before_filter :event
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

  def get_models_and_columns
    ret = ""
    Dir.new("#{RAILS_ROOT}/app/models").entries.each do |model|
      unless %w[. .. obsolete].include?(model)
        mdl = model.camelize.gsub('.rb', '')
        begin
          mdl.constantize.content_columns.each do |col|
            ret += "<option>#{mdl}.#{col.name}</option>" unless %w[created_at updated_at owner].include?(col.name)
          end
        rescue # do nothing
        end
      end
    end
    ret
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

  def get_themes(default)
    #renvoie la liste des themes
    dirname = "#{Rails.root}/public/stylesheets/*"
    ret = ""
    Dir[dirname].each do |dir|
      if File.directory?(dir)
        theme = File.basename(dir, '.*')
        if theme == default
          ret << "<option selected=\"selected\">#{theme}</option>"
        else
          ret << "<option>#{theme}</option>"
        end
      end
    end
    ret
  end

  def get_languages
    #renvoie la liste des langues
    dirname = "#{Rails.root}/config/locales/*.yml"
    ret = []
    Dir[dirname].each do |dir|
      lng = File.basename(dir, '.*')
      ret << [t("language_"+lng), lng]
    end
    #puts "application_controller.get_languages"+dirname+"="+ret.inspect
    ret
  end

  def get_html_options(lst, default, translate=false)
    ret=""
    lst.each do |item|
      if translate
        val=t(item[1])
      else
      val=item[1]
      end
      if item[0].to_s == default.to_s
        #puts "get_html_options:"+item.inspect+" = "+default.to_s
        ret << "<option value=\"#{item[0]}\" selected=\"selected\">#{val}</option>"
      else
        ret << "<option value=\"#{item[0]}\">#{val}</option>"
      end
    end
    #puts "application_controller.get_html_options:"+ret
    ret
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

  #
  # Should return the path to the partial in charge of rendering the
  # workitem payload.
  #
  # This initial implementation is rather, plain. Rewrite at will.
  #
  def determine_payload_partial (workitem)
    'shared/ruote_forms'
  end

  def authorize
    unless session[:user_id] || User.find_by_id(session[:user_id])
      puts "application_controller.request.request_uri="+request.request_uri
      puts "application_controller.request.new_sessions_url="+new_sessions_url
      session[:original_uri] = request.request_uri
      flash[:notice] = t(:login_login)
      redirect_to new_sessions_url
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

