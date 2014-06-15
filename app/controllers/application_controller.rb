require_dependency 'filters/log_definition_filter'
require_dependency 'controllers/plm_event'
require_dependency 'controllers/plm_object_controller_module'
require_dependency 'error_reply'

#require "string_to_sha1/version"
####require "string_to_sha1"
require "sylrplm_ext"
#require "digest/sha1"

class ApplicationController < ActionController::Base
  include Controllers::PlmObjectControllerModule
  helper :all # include all helpers, all the time
  helper_method :current_user, :logged_in?, :admin_logged_in?, :param_equals?, :get_domain, :get_list_modes, :icone, :h_thumbnails, :tr_def
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  filter_parameter_logging :password
  # bug: page non affichee before_render :check_access_data
  before_filter LogDefinitionFilter
  before_filter :check_init
  before_filter :authorize, :except => [:index, :init_objects]
  before_filter :check_user
  before_filter :define_variables
  before_filter :set_locale
  before_filter :active_check
  
	def active_check
    @my_filter = true
  end
  
  def render(*args) 
  	fname= "#{self.class.name}.#{__method__}"
  	#LOG.debug (fname) {"args=#{args}"}
  	if args.nil? || args.count==0
  		super
  	else
  	# args=[{:action=>"index"}]
		err = nil
		unless(args[0][:action] == "index" || (@_params[:controller]=="typesobject" && @_params[:action]=="edit"))
			err = check_database_consistency(args)
		end 
		#LOG.debug (fname) {"args.action=#{args[0][:action]} err=#{err} err.nil?=#{err.nil?}"}
  	if(err.nil? || err=="")
	    if @my_filter
	    	st = check_access_data(args) 
	    else
	    	st = true
	    end
	    if st == true
	    	#true
	    	super
	    else
	    	#false 
	    	msg = t(:data_access_forbidden)
	    	#LOG.debug (fname) {msg}
	    	redirect_to_main(nil, msg)
	    end
    else
    	msg=t(:database_not_consistency, :msg=>err)
    	LOG.error (fname) {msg}
    	redirect_to_main(nil ,msg)
    end
    end
  end
  
  #
  # check some point to be sure of the consistency of the database
  # host name, used for fog files ..., define by rake sylrplm:import_domain[db/custos/sicm,sicm.custo_base,limours]
  #
  def check_database_consistency(*args)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"args=#{args}"}
		ret = nil
		if Datafile.host.nil?
			# "Host not defined, define it in Type object property/sites/central=xxx"
			ret = t(:host_not_defined) 
		end
		ret
  end
  
  # return true if user have access on the data
	def check_access_data(*args)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"************** args=#{args}"}
		##############instance_variable_names.each  {|vi| LOG.debug (fname) {"#{vi} = #{eval vi}"}}
		#@current_user = syl/creator/SICM/
		#index:
		#@_params = {"controller"=>"documents", "action"=>"index"}
		#@documents = {:recordset=>[#<Document id: 2, owner_id: 101, typesobject_id: 873691851, statusobject_id: 4, next_status_id: nil, previous_status_id: nil, ident: "DOC000064", revision: "0", designation: "Designation document", description: "", date: "2013-12-07", created_at: "2013-12-07 09:45:44", updated_at: "2013-12-07 09:45:44", group_id: 101, projowner_id: 2, domain: "", type_values: nil>], :query=>nil, :page=>nil, :total=>1, :nb_items=>nil, :conditions=>["( group_id in (101) or projowner_id in (2))", {}]}
		#show
		#@_params = {"controller"=>"documents", "action"=>"show", "id"=>"2", "view_id"=>1}
		#@document = DOC000064/0-Designation document-cdc-inwork
		#edit
		#@_params = {"controller"=>"documents", "action"=>"edit", "id"=>"2"}
		#@document = DOC000064/0-Designation document-cdc-inwork
		#@types = [#<Typesobject id: 1016696961, forobject: "document", n...
		#new
		#@_params = {"controller"=>"documents", "action"=>"new"}
		#@document = DOC000067/0-Designation document-directory-inwork
		#@types = [#<Typesobject id: 1045584116, forobject: "document", name: "any_type", fields: "{}", description: "", created_at: "2013-12-06 17:53:07", updated_at: "2013-12-06 17:53:07", domain: "admin">, #<Typesobject id: 1016696961, forobject: "document", name: "calculsheet", fields: "{\"ref_doc\": \"\"}", description: "Feuille de calcul", created_at: "2013-12-06 17:53:07", updated_at: "2013-12-06 17
		#edit_lifecycle
		#@_params = {"controller"=>"documents", "action"=>"edit_lifecycle", "id"=>"2"}
		#@document = DOC000064/0-Designation document-cdc-inwork
		#add_favori
		#@_params = {"authenticity_token"=>"1UofyUu3oSh/gswSNcrVVuiSklPBsIroOCERrKBZEEc=", "controller"=>"documents", "action"=>"add_favori", "id"=>"2"}
		#dupliquer
		#@_params = {"controller"=>"documents", "action"=>"new_dup", "id"=>"2"}
		#@object_orig = DOC000064/0-Designation document-cdc-inwork
		#@object = DOC000069/0-Designation document-cdc-inwork
		#@document = DOC000069/0-Designation document-cdc-inwork
		#@types = [#<Typesobject id: 1045584116, forobject: "document", name: "any_type", fiel
		#
		#
		if @_params[:controller]=="main" && @_params[:action]=="index"
			ret=true
		else
			ret=true #false
		end
		ret
	end

	#
	# if action <> show, check if the user can create or update plm object (by accessor function)
	#   he must have a role, group and project
	# if not, redirect to index page
	#
  def check_user(redirect=true)
  	fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"redirect=#{redirect}, params=#{params} action=#{params[:action][0,4]}"}
    flash[:notice] = nil
    if(params[:action][0,3]!="show")
	    unless current_user.nil? || current_user.may_access?
	      flash[:notice] =""
	      flash[:notice] += t(:ctrl_user_without_roles )+" " if current_user.role.nil?
	      flash[:notice] += t(:ctrl_user_without_groups )+" " if current_user.group.nil?
	      flash[:notice] += t(:ctrl_user_without_projects )+" " if current_user.project.nil?
	      redirect_to(:action => "index") if redirect && !flash[:notice].blank?
	    end
    end
    flash[:notice]
  end

  def check_user_connect(user)
    flash[:error] = nil
    if false
      if !user.may_connect?
        flash[:error] =""
        flash[:error] += t(:ctrl_user_not_valid,:user=>user )+" " if user.typesobject.nil?
        flash[:error] += t(:ctrl_user_without_roles )+" " if user.roles.empty?
        flash[:error] += t(:ctrl_user_without_groups )+" " if user.groups.empty?
        flash[:error] += t(:ctrl_user_without_projects )+" " if user.projects.empty?
        flash[:error] = nil if flash[:notice].empty?
      end
    end
    flash[:error] = t(:ctrl_user_not_valid,:user=>user ) unless user.may_connect?
    puts "check_user_connect:"+user.inspect+":"+flash[:notice].to_s
    if user.login==PlmServices.get_property(:USER_ADMIN)
      flash[:error] = nil
    end
    flash[:error]
  end

  def check_init
    if User.count == 0
    	LOG.error (fname) {"Database is empty (no user)"}
      flash[:error]=t(:ctrl_init_to_do)
      respond_to do |format|
        format.html{redirect_to_main}
      end
    end
  end

  def event
    event_manager
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
    #puts "set_locale:params[:locale]=#{params[:locale]}"
    if params[:locale]
      I18n.locale = params[:locale]
      session[:lng] = I18n.locale
    else
      unless @current_user.nil?
        #puts "set_locale:@current_user=#{@current_user} lng=#{@current_user.language}"
        I18n.locale = @current_user.language
      else
        if session[:lng]
          I18n.locale = session[:lng]
        else
          I18n.locale = PlmServices.get_property(:LOCAL_DEFAULT)
          session[:lng] = I18n.locale
        end
      end
    end
    #puts "fin de set_locale"
  end
  
  # definition du domain en cours
  def set_domain
    if params[:domain]
      session[:domain] = params[:domain]
    end
  end
  
  def get_domain
  	if session[:domain].nil? ||  session[:domain]==""
  		 ret=PlmServices.get_property(:DOMAIN_DEFAULT)
  		 ret+=current_user.login unless current_user.nil?
  	else
  		ret=session[:domain]
  	end
  	ret
  end
  
  # definition des variables globales.
  def define_variables
  	fname= "#{self.class.name}.#{__method__}"
  	###puts "************************************************** #{fname.to_sha1} **********************************************"
    @favori      = session[:favori] ||= Favori.new
    @theme       = User.find_theme(session)
    @language    = PlmServices.get_property(:LOCAL_DEFAULT)
	  @urlbase     = "http://"+request.env["HTTP_HOST"]
    @themes      = get_themes(@theme)
    @languages   = get_languages
    ###########TODO inutile @notification=PlmServices.get_property(:NOTIFICATION_DEFAULT)
    ###########TODO inutile @time_zone=PlmServices.get_property(:TIME_ZONE_DEFAULT)
    WillPaginate::ViewHelpers.pagination_options[:previous_label] = t('label_previous')
    WillPaginate::ViewHelpers.pagination_options[:next_label] = t('label_next')
    WillPaginate::ViewHelpers.pagination_options[:page_links ] = true  # when false, only previous/next links are rendered (default: true)
    WillPaginate::ViewHelpers.pagination_options[:inner_window] = 10 # how many links are shown around the current page (default: 4)
    WillPaginate::ViewHelpers.pagination_options[:page_links ] = true  # when false, only previous/next links are rendered (default: true)
    WillPaginate::ViewHelpers.pagination_options[:inner_window] = 10 # how many links are shown around the current page (default: 4)
    WillPaginate::ViewHelpers.pagination_options[:outer_window] = 3 # how many links are around the first and the last page (default: 1)
    WillPaginate::ViewHelpers.pagination_options[:separator ] = ' - '   # string separator for page HTML elements (default: single space)
  	@myparams = params
		Datafile.host=request.host
  	#puts "fin de define_variables"
  end
  
  def get_list_modes
  	[t(:list_mode_details), t(:list_mode_details_icon),t(:list_mode_icon)]
  end

  # redirection vers l'action index
  def redirect_to_index(msg=nil)
    flash[:notice] = msg if msg
    redirect_to :action => index
  end

  # redirection vers l'action index du main si besoin
  def redirect_to_main(uri=nil, msg=nil)
  	puts "redirect_to_main"
    flash[:error] = msg if msg
    redirect_to(uri || { :controller => "main", :action => "index" })
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

  def authorize
    user_id = session[:user_id] || User.find_by_id(session[:user_id])
    if user_id.nil?
      puts "authorize:user is nil"
      #puts "application_controller.authorize.request_uri="+request.request_uri
      #puts "application_controller.authorize.new_sessions_url="+new_sessions_url
      session[:original_uri] = request.request_uri
      flash[:notice] = t(:login_login)
      redirect_to new_sessions_url
    else
      user=User.find(user_id)
      #puts "authorize:user=#{user} admin?=#{user.is_admin?}"
      unless user.is_admin?
      	#puts "user not admin, user.roles=#{user.roles} user.groups=#{user.groups} user.projects=#{user.projects}"
        if user.roles.nil? || user.groups.nil? || user.projects.nil?
          #puts "authorize:roles=#{user.roles}  "
          #puts "authorize:groups=#{user.groups}  "
          #puts "authorize:projects=#{user.projects}  "
          session[:original_uri] = request.request_uri
          flash[:notice] = t(:login_login)
          redirect_to new_sessions_url
        end
      end
      if user.roles.nil?  || user.groups.nil? || user.projects.nil? || user.volume.nil?
          #puts "authorize:roles=#{user.roles}  "
          #puts "authorize:groups=#{user.groups}  "
          #puts "authorize:projects=#{user.projects}  "
          #puts "authorize:volume=#{user.volume} "
	  			session[:original_uri] = request.request_uri
          flash[:notice] = t(:login_login)
          redirect_to new_sessions_url
      end
    end
    #puts "fin de authorize"
  end
  
  def permission_denied(role, controller, action)
  	fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"role=#{role} controller=#{controller} action=#{action}"}
    flash[:error] = t(:ctrl_no_privilege, :role => role, :controller => controller, :action => action)
    redirect_to(:action => "index")
  end

  def permission_granted
    #flash[:notice] = "Welcome to the secure area !"
  end

  def current_user
    ret = @current_user ||= User.find_user(session)
    ret.session_domain=session[:domain] unless ret.nil? || session[:domain].nil?
    ret
  end

  def logged_in?
    current_user != nil
  end

  # Returns true if the user is connected and having an admin role
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

  def icone(object)
		html_title=""
		unless object.typesobject.nil?
			#type = "#{object.model_name}_#{object.typesobject.name}"
			mdl_name = t("typesobject_name_#{object.typesobject.name}")
			html_title="title='#{mdl_name}'"
		end
		fic = icone_fic(object)
		ret = "<img class='icone' src='#{fic}' #{html_title}></img>"
		unless @myparams[:list_mode].blank?
			if @myparams[:list_mode] != t(:list_mode_details)
				ret << h_thumbnails(object)
			end
		end
		ret
	end

	def icone_fic(obj)
  	fname="#{controller_class_name}.#{__method__}"
    unless obj.model_name.nil? || !obj.respond_to?(:typesobject) || obj.typesobject.nil?
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
    #LOG.debug  (fname){"icone:#{obj.model_name}:#{obj.typesobject.name}:#{ret}"}
    ret
  end
  
	#
	# return the image corresponding of an object of plmtype(user, group, customer, part, document, project, ...)
	#
  def icone_plmtype(plmtype)
    ret = "/images/#{plmtype}.png"
    unless File.exist?("#{RAILS_ROOT}/public#{ret}")
      ret = ""
    end
    ret
  end
  
	#
	# verifie qu'un parametre http existe avec la bonne valeur
	#
	def param_equals?(key, value)
		ret = @myparams.include?(key) && @myparams[key] == value
		#puts "#{controller_name}.#{__method__}:#{key}.#{value}=#{ret}"
		ret
	end
	
	def h_thumbnails(obj)
		ret=""
		if obj.respond_to? :thumbnails
			unless obj.thumbnails.nil?
				obj.thumbnails.each do |img|
					ret << "<img class='thumbnail' src=\"#{img.write_file_tmp}\"></img>"
				end
			end
		end
		ret
	end
	
	def tr_def(key)
		t(key,:default=> "%#{key}%")
	end
	
	def t(*args)
		tr=PlmServices.translate(args)
		#puts "t:#{args.inspect} env:#{Rails.env}:#{tr}"
		tr=tr[0] if tr.is_a?(Array)
		tr
	end
end

