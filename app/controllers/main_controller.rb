require 'classes/controller'

class MainController < ApplicationController

	#access_control(Access.find_for_controller(controller_class_name))
	skip_before_filter :authorize
	#def infos
	#  request.env["PATH_INFO"] +":"+__FILE__+":"+__LINE__.to_s
	#end
	def index
		fname= "#{self.class.name}.#{__method__}"
		
		unless params[:domain].blank?
			# creation du domaine demande: status et types d'objets
			st=Controller.init_db(params)
			flash[:notice] = t(:ctrl_init_done)
		else
			@domains = Controller.get_domains
			@directory = PlmServices.get_property(:VOLUME_DIRECTORY_DEFAULT)
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
		if @theme.nil?
			@theme="white"
		end
		unless params[:locale].nil?
			set_locale
			unless @current_user.nil?
				@current_user.language = params[:locale]
			st = @current_user.save
			end
		end
		unless params[:domain].nil?
			set_domain
		end

		unless @current_user.nil?
			opts = { :order => 'dispatch_time DESC' }
			opts[:conditions] = { :store_name => @current_user.store_names }
			opts[:page] = (params[:page].nil? ? PlmServices.get_property(:NB_ITEMS_PER_PAGE).to_i :  params[:page])
			@workitems = Ruote::Sylrplm::ArWorkitem.paginate_by_params(
	[# parameter_name[, column_name]
	'wfid',[ 'workflow', 'wfname' ],	[ 'store', 'store_name' ],	[ 'participant', 'participant_name' ]
	],
	params,
	opts)
		end
		#LOG.debug (fname) {"@workitems=#{@workitems.inspect}"}
		respond_to do |format|
			@main=true
			format.html # index.html.erb
		end

	end

	def helpgeneral
		#puts " helpgeneral"
		respond_to do |format|
			format.html # helpgeneral.html.erb
		end
	end

end