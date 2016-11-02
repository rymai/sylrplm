require_dependency 'filters/log_definition_filter'
require_dependency 'controllers/plm_event'
require_dependency 'controllers/plm_object_controller_module'
require_dependency 'error_reply'
require_dependency 'acl_system2/lib/caboose/access_control'

require "sylrplm_ext"

class ApplicationController < ActionController::Base
	include Controllers::PlmObjectControllerModule
	include Caboose::AccessControl
	# include all helpers, all the time
	respond_to :html, :js, :json
	helper :all
	helper_method :current_user, :logged_in?, :admin_logged_in?, :param_equals?, :get_domain, :get_list_modes, :icone, :h_thumbnails, :tr_def
	helper_method :get_controller_from_model_type, :icone_fic
	# See ActionController::RequestForgeryProtection for details
	#rails2 protect_from_forgery

	# bug: page non affichee before_render :check_access_data
	#rails4 ko before_filter LogDefinitionFilter
	before_filter :run_debug
	before_filter :check_init
	before_filter :authorize, :except => [:index, :init_objects]
	before_filter :check_user
	before_filter :define_variables
	before_filter :set_locale
	before_filter :active_check

  ##### after_filter :manage_recents

	def run_debug
	   	if Rails.env=="development"
	   		#byebug
	   		#console
	   	end
	end
	def manage_recents
		fname = "#{self.class.name}.#{__method__}:"
		#LOG.info(fname) {"params=#{params}, user=#{current_user}, plm_object=#{@plm_object}"}
		if logged_in?
			unless params[:id].nil?
				object_plm= PlmServices.get_object(get_model_type(params), params[:id])
				current_user.manage_recents object_plm, params unless object_plm.nil?
				end
			end
		true
	end

	def active_check
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"active_check"}
		@my_filter = true
	end

	def render_(*args)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {">>>>args=#{args.inspect} flash=#{flash.inspect}"}
		if args.nil? || args.count==0
		super
		else
		# args=[{:action=>"index"}]
			err = nil
			unless(args[0]["action"] == "index" || (@_params["controller"]=="typesobject" && @_params["action"]=="edit"))
				err = check_database_consistency(args)
			end
			#LOG.debug(fname) {"args.action=#{args[0][:action]} err=#{err} err.nil?=#{err.nil?}"}
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
					#LOG.debug(fname) {msg}
					redirect_to_main(nil, msg)
				end
			else
				msg=t(:database_not_consistency, :msg=>err)
				LOG.error(fname) {msg}
				redirect_to_main(nil ,msg)
			end
		end
		LOG.debug(fname) {"<<<< flash=#{flash.inspect}"}
	end

	#
	# check some point to be sure of the consistency of the database
	# host name, used for fog files ..., define by rake sylrplm:import_domain[db/custos/sicm,sicm.custo_base,limours]
	#
	def check_database_consistency(*args)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname) {"args=#{args}"}
		ret = nil
		if Datafile.host.nil?
			# "Host not defined, define it in Type object property/sites/SITE_CENTRAL=xxx"
			ret = t(:host_not_defined)
		end
		ret
	end

	# return true if user have access on the data
	def check_access_data(*args)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname) {"************** args=#{args}"}
		##############instance_variable_names.each  {|vi| LOG.debug(fname) {"#{vi} = #{eval vi}"}}
		#@current_user = syl/creator/SICM/
		#index:
		#@_params = {"controller"=>"documents", "action"=>"index"}
		#@object_plms = {:recordset=>[#<Document id: 2, owner_id: 101, typesobject_id: 873691851, statusobject_id: 4, next_status_id: nil, previous_status_id: nil, ident: "DOC000064", revision: "0", designation: "Designation document", description: "", date: "2013-12-07", created_at: "2013-12-07 09:45:44", updated_at: "2013-12-07 09:45:44", group_id: 101, projowner_id: 2, domain: "", type_values: nil>], :query=>nil, :page=>nil, :total=>1, :nb_items=>nil, :conditions=>["( group_id in (101) or projowner_id in (2))", {}]}
		#show
		#@_params = {"controller"=>"documents", "action"=>"show", "id"=>"2", "view_id"=>1}
		#@object_plm = DOC000064/0-Designation document-cdc-inwork
		#edit
		#@_params = {"controller"=>"documents", "action"=>"edit", "id"=>"2"}
		#@object_plm = DOC000064/0-Designation document-cdc-inwork
		#@types = [#<Typesobject id: 1016696961, forobject: "document", n...
		#new
		#@_params = {"controller"=>"documents", "action"=>"new"}
		#@object_plm = DOC000067/0-Designation document-directory-inwork
		#@types = [#<Typesobject id: 1045584116, forobject: "document", name: "any_type", fields: "{}", description: "", created_at: "2013-12-06 17:53:07", updated_at: "2013-12-06 17:53:07", domain: "admin">, #<Typesobject id: 1016696961, forobject: "document", name: "calculsheet", fields: "{\"ref_doc\": \"\"}", description: "Feuille de calcul", created_at: "2013-12-06 17:53:07", updated_at: "2013-12-06 17
		#edit_lifecycle
		#@_params = {"controller"=>"documents", "action"=>"edit_lifecycle", "id"=>"2"}
		#@object_plm = DOC000064/0-Designation document-cdc-inwork
		#add_clipboard
		#@_params = {"authenticity_token"=>"1UofyUu3oSh/gswSNcrVVuiSklPBsIroOCERrKBZEEc=", "controller"=>"documents", "action"=>"add_clipboard", "id"=>"2"}
		#dupliquer
		#@_params = {"controller"=>"documents", "action"=>"new_dup", "id"=>"2"}
		#@object_orig = DOC000064/0-Designation document-cdc-inwork
		#@object = DOC000069/0-Designation document-cdc-inwork
		#@object_plm = DOC000069/0-Designation document-cdc-inwork
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
		#LOG.debug(fname) {"redirect=#{redirect}, params=#{params} action=#{params[:action][0,4]}"}
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
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {">>>>user=#{user}"}
		msg = t(:ctrl_user_not_valid,:user=>user ) unless user.may_connect?
		#puts "check_user_connect:"+user.inspect+":"+flash[:notice].to_s
		if user.login==PlmServices.get_property(:USER_ADMIN)
			msg = nil
		end
		LOG.debug(fname) {"<<<<user=#{user} msg=#{msg}"}
		msg
	end

	def check_init
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {">>>>"}
		if User.count == 0
			LOG.error(fname) {"Database is empty (no user)"}
			flash[:error]=t(:ctrl_init_to_do)
			LOG.debug(fname) {"<<<<flash[:error]=#{flash[:error]}"}
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
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {">>>>"}
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
	LOG.debug(fname) {"<<<<session=#{session}"}
	end

	# definition du domain en cours
	def set_domain
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {">>>>"}
		if params[:domain]
			session[:domain] = params[:domain]
		end
		LOG.debug(fname) {"<<<<session[:domain]=#{session[:domain]}"}
	end

	def get_domain
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {">>>>"}
		if session[:domain].nil? ||  session[:domain]==""
			ret=PlmServices.get_property(:DOMAIN_DEFAULT)
			ret+=current_user.login unless current_user.nil?
		else
			ret=session[:domain]
		end
		LOG.debug(fname) {"<<<<session[:domain]=#{session[:domain]} ret=#{ret}"}
		ret
	end

	# recherche du theme
	def get_session_theme(session)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {">>>> session=#{session}"}
		ret = PlmServices.get_property(:THEME_DEFAULT)
		LOG.debug(fname) {"session=#{session} theme_default=#{ret}"}
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
		LOG.debug(fname) {"<<<< session=#{session} theme=#{ret}"}
		ret
	end

	# definition des variables globales.
	def define_variables
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {">>>>params=#{params.inspect}"}
		@views = View.all
		@current_user= current_user
		@clipboard      = session[:clipboard] ||= Clipboard.new
		#LOG.info(fname) {"**** clipboard=#{@clipboard.inspect}"}
		@theme       = get_session_theme(session)
		LOG.debug(fname) {"@theme=#{@theme}"}
		@language    = PlmServices.get_property(:LOCAL_DEFAULT)
		LOG.debug(fname) {"@language=#{@language}"}
		@urlbase    = get_urlbase
		LOG.debug(fname) {"@urlbase=#{@urlbase}"}
		@themes      = get_themes(@theme)
		LOG.debug(fname) {"@themes=#{@themes}"}
		@languages   = get_languages
		LOG.debug(fname) {"@languages=#{@languages}"}
		@datas = get_datas_count
		LOG.debug(fname) {"@datas=#{@datas}"}
		###########TODO inutile @notification=PlmServices.get_property(:NOTIFICATION_DEFAULT)
		###########TODO inutile @time_zone=PlmServices.get_property(:TIME_ZONE_DEFAULT)
		WillPaginate::ViewHelpers.pagination_options[:previous_label] = t('label_previous')
		WillPaginate::ViewHelpers.pagination_options[:next_label] = t('label_next')
		# when false, only previous/next links are rendered (default: true)
		WillPaginate::ViewHelpers.pagination_options[:page_links ] = true
		# how many links are shown around the current page (default: 4)
		WillPaginate::ViewHelpers.pagination_options[:inner_window] = 10
		# when false, only previous/next links are rendered (default: true)
		WillPaginate::ViewHelpers.pagination_options[:page_links ] = true
		# how many links are shown around the current page (default: 4)
		WillPaginate::ViewHelpers.pagination_options[:inner_window] = 10
		# how many links are around the first and the last page (default: 1)
		WillPaginate::ViewHelpers.pagination_options[:outer_window] = 3
		# string separator for page HTML elements (default: single space)
		WillPaginate::ViewHelpers.pagination_options[:separator ] = ' - '
		@myparams = params
		Datafile.host=request.host
		@types_features=::Controller.get_types_by_features
		flash[:notice]=""
		flash[:error]=""
		LOG.debug(fname) {"<<<<params=#{params.inspect}"}
	end

	def get_urlbase
		ret    = request.env["HTTP_REFERER"]
		if ret.nil?
			ret="http://#{request.env["HTTP_HOST"]}" # until request.env["HTTP_HOST"].nil?
		end
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
		puts "application_controller: redirect_to_main:flash=#{flash.inspect}"
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
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){">>>>>>>>>> #{request.env['REQUEST_URI']} >>>>>>>>>>>>>>>>>>>>>>>"}
		LOG.debug(fname){"params=#{params}"}
		unless session[:user_id].nil?
		user_id = session[:user_id] || User.find(session[:user_id])
		end
		#LOG.debug(fname){"request_uri=#{request.env["REQUEST_URI"]} user_id=#{user_id}"}
		if user_id.nil?
			#LOG.debug(fname){"user is nil: new_sessions_url=#{new_sessions_url}"}
			session[:original_uri] = request.env["REQUEST_URI"]
			flash[:notice] = t(:login_login)
			LOG.debug(fname){"user is nil: redirect_to #{new_session_url}  "}
			redirect_to new_session_url
		else
			user=User.find(user_id)
			LOG.debug(fname){"user=#{user} admin?=#{user.is_admin?}"}
			if user.roles.nil?  || user.groups.nil? || user.projects.nil? || user.volume.nil?
				LOG.debug(fname){"roles=#{user.roles} "}
					LOG.debug(fname){"groups=#{user.groups}  "}
					LOG.debug(fname){"projects=#{user.projects}  "}
				LOG.debug(fname){"volume=#{user.volume} "}
				session[:original_uri] = request.request_uri
				flash[:notice] = t(:login_login)
				LOG.debug(fname){"user incomplet redirect_to #{new_sessions_url}  "}
				redirect_to new_sessions_url
			end
		end
		LOG.debug(fname){"<<<<<<<<<<< OKOKOK <<<<<<<<<<<<<<<<"}
	end

	def permission_denied(role, controller, action)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"role=#{role} controller=#{controller} action=#{action}"}
		flash[:error] = t(:ctrl_no_privilege, :role => role, :controller => controller, :action => action)
		redirect_to(:action => "index")
	end

	def permission_granted
		#flash[:notice] = "Welcome to the secure area !"
	end

	def current_user
		# recherche du user connecte
		ret = @current_user
		if ret.nil?
			if session[:user_id]
				ret = User.find(session[:user_id])
			end
		end
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
		fname= "#{self.class.name}.#{__method__}"
		html_title=""
		type=object.typesobject
		unless type.nil?
			LOG.debug(fname) {"object=#{object} typesobject=#{type} "}
			begin
			mdl_name = t("typesobject_name_#{type.name}")
			html_title="title='#{mdl_name}'"
		rescue Exception=>e
						LOG.warn(fname) {"Exception:#{e}"}
		end
		end
		fic = icone_fic(object)
		ret = "<img class='icone' src='#{fic}' #{html_title}/>"
		unless @myparams[:list_mode].blank?
			if @myparams[:list_mode] != t(:list_mode_details)
				ret << h_thumbnails(object)
			end
		end
		ret.html_safe
	end

	def icone_fic(obj)
		fname="#{self.class.name}.#{__method__}"
		unless obj.modelname.nil? || !obj.respond_to?(:typesobject) || obj.typesobject.nil?
			begin
				ret = "/images/#{obj.modelname}_#{obj.typesobject.name}.png"
			rescue Exception=>e
						LOG.warn(fname) {"Exception:#{e}"}
				ret = "/images/#{obj.modelname}.png"
			end
			unless File.exist?("#{Rails.root}/public#{ret}")
				ret = "/images/#{obj.modelname}.png"
				unless File.exist?("#{Rails.root}/public#{ret}")
					ret = "/images/default_object.png"
					unless File.exist?("#{Rails.root}/public#{ret}")
						ret = ""
					end
				end
			end
		else
			ret = ""
		end
		#LOG.debug  (fname){"icone:#{obj.modelname}:#{obj.typesobject.name}:#{ret}"}
		ret
	end

	#
	# return the image corresponding of an object of plmtype(user, group, customer, part, document, project, ...)
	#
	def icone_plmtype(plmtype)
		ret = "/images/#{plmtype}.png"
		unless File.exist?("#{config.root}/public#{ret}")
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
		fname="#{self.class.name}.#{__method__}"
		ret=""
		if obj.respond_to? :thumbnails
			unless obj.thumbnails.nil?
				obj.thumbnails.each do |img|
					src = img.write_file_tmp
					LOG.debug(fname) {"src=#{src} "}
					ret << "<img class='thumbnail' src='#{src}'/>"
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
		tr=tr[0] if tr.is_a?(Array)
		#puts "t:#{args.inspect} env:#{Rails.env}:#{tr}"
		tr
	end

		# DELETE /parts/1
	# DELETE /parts/1.xml
		#menu index/delete "controller"=>"parts", "action"=>"destroy", "id"=>"36"
		#action index/supprime "commit"=>"Supprime", "_method"=>"delete", "action_on"=>{"1"=>"0", "3"=>..."0", "35"=>"0"}, "controller"=>"parts", "action"=>"destroy", "id"=>"action"
	def destroy
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"destroy.params=#{params.inspect}"}
		ctrl_destroy
	end

	# get the current object from portal informations
	def get_object_plm_from_params(params)
		ret=nil
		unless params[:object_plm_model].nil? || params[:object_plm_id].nil?
			ret=PlmServices.get_object(params[:object_plm_model],params[:object_plm_id])
		end
		ret
	end

end

