require 'controllers/plm_event'
require 'controllers/plm_favorites'
require 'controllers/plm_lifecycle'
require 'controllers/plm_tree'
require 'controllers/plm_object_controller_module'

class ErrorReply < Exception
  attr_reader :status
  def initialize (msg, status=400)
    super(msg)
    @status = status
  end
end

class LogDefinitionFilter
  def self.filter(controller)
      LOG.progname=controller.controller_class_name+"."+controller.action_name
  end
end

class ApplicationController < ActionController::Base
  include Controllers::PlmObjectControllerModule

  helper :all  # include all helpers, all the time
  helper_method :current_user, :logged_in?, :admin_logged_in?

  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  filter_parameter_logging :password
  
  before_filter LogDefinitionFilter
  
  before_filter :authorize, :except => [:index, :show, :init_objects]
  before_filter :set_locale
  before_filter :define_variables
  #
  def update_accessor(obj)
    mdl_name = obj.model_name
    params[mdl_name][:owner_id]=current_user.id if obj.instance_variable_defined?(:@owner_id)
    params[mdl_name][:group_id]=current_user.group_id if obj.instance_variable_defined?(:@group_id)
    params[mdl_name][:projowner_id]=current_user.project_id if obj.instance_variable_defined?(:@projowner_id)
    puts "update_accessor:"+params.inspect
  end
	
  def check_user(redirect=true)
    flash[:notice] = nil
    if !current_user.may_access?
      flash[:notice] =""
      flash[:notice] += t(:ctrl_user_without_roles )+" " if current_user.role.nil?
      flash[:notice] += t(:ctrl_user_without_groups )+" " if current_user.group.nil?
      flash[:notice] += t(:ctrl_user_without_projects )+" " if current_user.project.nil?
      #puts "check_user:"+redirect.to_s+":"+flash[:notice]
      redirect_to(:action => "index") if redirect && !flash[:notice].empty?
    end
    flash[:notice]
  end

  def check_user_connect(user)
    flash[:notice] = nil
    if false
      if !user.may_connect?
        flash[:notice] =""
        flash[:notice] += t(:ctrl_user_not_valid,:user=>user )+" " if user.typesobject.nil?
        flash[:notice] += t(:ctrl_user_without_roles )+" " if user.roles.empty?
        flash[:notice] += t(:ctrl_user_without_groups )+" " if user.groups.empty?
        flash[:notice] += t(:ctrl_user_without_projects )+" " if user.projects.empty?
        flash[:notice] = nil if flash[:notice].empty?
      end
    end
    flash[:notice] = t(:ctrl_user_not_valid,:user=>user ) unless user.may_connect?
    puts "check_user_connect:"+user.inspect+":"+flash[:notice].to_s
    if user.login==::SYLRPLM::USER_ADMIN
      flash[:notice] = nil
    end
    flash[:notice]
  end

  def check_init
    if User.count == 0
      puts 'application_controller.check_init:base vide'
      flash[:notice]=t(:ctrl_init_to_do)
      respond_to do |format|
        format.html{redirect_to_main}
      end
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
      :plm_objects => {
        :datafile => Datafile.count,
        :document => Document.count,
        :part => Part.count,
        :project => Project.count,
        :customer => Customer.count},
      :collab_objects => {
        :forum => Forum.count,
        :question => Question.count},
      :internal_objects => {
        :link => Link.count},
      :admin => {
        :user => User.count,
        :role => Role.count,
        :group => Group.count,
        :volume => Volume.count,
        :typesobject => Typesobject.count,
        :statusobject => Statusobject.count,
        :relation => Relation.count},
      :workflow_objects => {
        :definition => Definition.count
      }
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
    Ruote::Sylrplm::HistoryEntry.log!(source, event, options)
  end

  def authorize
    user_id = session[:user_id] || User.find_by_id(session[:user_id])
    if user_id.nil?
      #puts "application_controller.authorize.request_uri="+request.request_uri
      #puts "application_controller.authorize.new_sessions_url="+new_sessions_url
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
        ret = current_user.is_admin?
      end
    end
    ret
  end
  
  def icone(obj)
  	fname="#{controller_class_name}.#{__method__}"
    unless obj.model_name.nil? || obj.typesobject.nil?
      ret = "/images/#{obj.model_name}_#{obj.typesobject.name}.png"
      unless File.exist?("#{RAILS_ROOT}/public#{ret}")
        ret = "/images/#{obj.model_name}.png"
        unless File.exist?("#{RAILS_ROOT}/public#{ret}")
          ret = "/images/default_object.png"
          unless File.exist?("#{RAILS_ROOT}/public#{ret}")
        	  ret = ""
        	end
      	end
      end
    else
      ret = ""
    end
    LOG.debug  (fname){"#{obj.model_name}:#{obj.typesobject.name}:#{ret}"}
    ret
  end
  
  def icone_plmtype(plmtype)
    ret = "/images/#{plmtype}.png"
    unless File.exist?("#{RAILS_ROOT}/public#{ret}")
      ret = ""
    end
    ret
  end
  
  
  #
  # controle des vues et de la vue active
  # 
  def define_view
  	# views: liste des vues possibles est utilisee dans la view ruby show
		@views = View.all
		# view_id: id de la vue selectionnee est utilisee dans la view ruby show
		if params["view_id"].nil?
		@view_id = @views.first.id
		else
			@view_id = params["view_id"]
		end
	end
end

