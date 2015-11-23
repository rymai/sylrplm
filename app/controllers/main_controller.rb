require 'classes/controller'

class MainController < ApplicationController

	#access_control(Access.find_for_controller(controller_class_name))
	skip_before_filter :authorize, :check_user
	#def infos
	#  request.env["PATH_INFO"] +":"+__FILE__+":"+__LINE__.to_s
	#end
	def index
		fname= "#{self.class.name}.#{__method__}"
		#LOG.info (fname){"params=#{params.inspect}"}
		unless params[:domain].blank?
			# creation du domaine demande: status et types d'objets
			st=Controller.init_db(params)
			flash[:notice] = t(:ctrl_init_done)
		else
			@domains = Controller.get_domains
			@directory = ::SYLRPLM::VOLUME_DIRECTORY_DEFAULT
		end
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

	def how_to
		fname= "#{self.class.name}.#{__method__}"
		@files={}
		urlbase="#{RAILS_ROOT}/public/how_to"
		Dir.new("#{urlbase}").entries.each do |doc|
			unless doc == "." || doc == ".."
				LOG.debug (fname) {"doc=#{doc}"}
				@files[doc]={}
				mdlfiles=[]
				docfiles=[]
				Dir.new("#{urlbase}/#{doc}").entries.each do |file|
					unless file =="." || file==".."
						if file == "files"
							Dir.new("#{urlbase}/#{doc}/#{file}").entries.each do |mdlfile|
								unless mdlfile =="." || mdlfile == ".."
								mdlfiles << "#{file}/#{mdlfile}"
								end
							end
						else
							docfiles << file
						end
					end
					LOG.debug (fname) {"file=#{file}"}
					@files[doc][:docfiles] = docfiles
					@files[doc][:mdlfiles] = mdlfiles
				end
			end
		end
		LOG.debug (fname) {"@files=#{@files}"}
	end

	def helpgeneral
		#puts " helpgeneral"
		respond_to do |format|
			format.html # helpgeneral.html.erb
		end
	end

end