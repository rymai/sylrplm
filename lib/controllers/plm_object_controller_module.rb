require_dependency 'controllers/plm_tree'
require_dependency 'controllers/tree_actions_by_roles'
require_dependency 'controllers/plm_favorites'
require_dependency 'controllers/plm_lifecycle'

module Controllers
	module PlmObjectControllerModule
	  # extend ActiveSupport::Concern

		def add_favori
			fname="#{controller_class_name}.#{__method__}"
			#LOG.info() { "params=#{params.inspect}" }
			model = get_model(params)
			model_name=get_model_type(params)
			obj = model.find(params[:id])
			@favori.add(obj)
			#LOG.info(fname) { "favori#{model_name}=#{@favori.get(model_name).count}" }
			respond_to do |format|
					format.js { render 'shared/refresh_favorites' }
			end
		end

		def empty_favori
	    fname="#{controller_class_name}.#{__method__}"
	    empty_favori_by_type(get_model_type(params))
			model_name=get_model_type(params)
			#LOG.info(fname) { "favori#{model_name}=#{@favori.get(model_name).count}" }
	    respond_to do |format|
	      format.js { render 'shared/refresh_favorites' }
	    end
	  end

		def ctrl_add_forum(object)
			fname = "#{self.class.name}.#{__method__}"
			#LOG.info (fname) { "params=#{params.inspect}" }
			#LOG.info (fname) { "object=#{object.inspect} " }
			#LOG.info (fname) { "typesobject=#{object.typesobject.inspect}" }

			relation = if params["relation_id"].empty?
				forum_type = Typesobject.find(params[:forum][:typesobject_id])
				Relation.by_types(object.model_name, "forum", object.typesobject.id, forum_type.id)
			else
				Relation.find(params["relation_id"])
			end
			error = false

			respond_to do |format|
				flash[:notice] = ""
				@forum = Forum.new(params[:forum].merge(user: current_user))
				@forum.owner = current_user
				if @forum.save
					#item = ForumItem.create_new(@forum, params, current_user)
					args={}
					args[:forum]=@forum
					args[:user]=current_user
					args[:message]=params[:message]
					item = ForumItem.new(args)
					if item.save
						if relation.nil?
							flash[:notice] << t(:ctrl_object_not_created,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>"no relation",:msg=>nil)
							@forum.destroy
							error = true
						else
							link = Link.new(father: object, child: @forum, relation: relation, user: current_user)
							if link.save
								flash[:notice] << t(:ctrl_object_added,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation.ident,:msg=>nil)
							else
								msg=link.errors.inspect
								flash[:notice] << t(:ctrl_object_not_added,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation.ident,:msg=>msg)
								@forum.destroy
								error = true
							end
							# else
							# 	msg = $!
							# 	flash[:notice] << t(:ctrl_object_not_linked,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation.ident,:msg=>msg)
							# 	@forum.destroy
							# 	error = true
							# end
						end
					else
						msg=item.errors.inspect
						flash[:notice] << t(:ctrl_object_not_created, :typeobj =>t(:ctrl_forum_item),:msg=>msg)
						@forum.destroy
						error = true
					end
				else
					flash[:notice] << t(:ctrl_object_not_saved,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation.ident,:msg=>nil)
					error = true
				end

				if error
					@types = Typesobject.find_for("forum")
					@status = Statusobject.find_for("forum")
					@object = object
					format.html { render :action => :new_forum, :id => object.id }
				else
					format.html { redirect_to(object) }
				end
				format.xml  { head :ok }
			end
		end

		def get_nb_items(nb_items)
			unless nb_items.nil? || nb_items==""
				unless @current_user.nil?
					if nb_items!=@current_user.nb_items
						@current_user.update_attributes({:nb_items=>nb_items})
					end
				end
			nb_items
			else
				unless @current_user.nil?
				@current_user.nb_items
				else
					unless session[:nb_items].nil?
						session[:nb_items]
					else
						PlmServices.get_property(:NB_ITEMS_PER_PAGE).to_i
					end
				end
			end
		end

		# enlever le 's' de fin
		# :controller=>parts devient part
		def get_model_type(params)
			name=self.class.name+"."+__method__.to_s+":"
			ret = case params[:controller]
			when "documents" then params[:controller].chop
			when "parts" then params[:controller].chop
			when "projects" then params[:controller].chop
			when "customers" then params[:controller].chop
			when "notifications" then params[:controller].chop
			when "users" then params[:controller].chop
			when "links" then params[:controller].chop
			else params[:controller]
			end
			#puts name+params[:controller]+"="+ret
			ret
		end

		def get_controller_from_model_type(model_type)
			# ajouter le 's' de fin
			# part devient parts
			model_type+"s"
		end

		def get_model(params)
			name=self.class.name+"."+__method__.to_s+":"
			# parts devient Part
			#puts name+params.inspect
			eval get_model_type(params).capitalize
		end

		def get_model_name(model)
			# Part devient part
			model.class.name.downcase
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

		def html_models_and_columns(default = nil)
			lst=[]
			Dir.new("#{RAILS_ROOT}/app/models").entries.each do |model|
				unless %w[. .. _obsolete _old Copy].include?(model)
					mdl = model.camelize.gsub('.rb', '')
					begin
						#mdl.constantize.content_columns.each do |col|
						mdl.constantize.columns.each do |col|
							lst<<["#{mdl}.#{col.name}","#{mdl}.#{col.name}"] unless %w[created_at updated_at owner].include?(col.name)
						end
					rescue
					# do nothing
					end
				end
			end
			##puts __FILE__+"."+__method__.to_s+":"+lst.inspect
			get_html_options(lst.sort, default)
		end

		def  get_html_options(lst, default, translate=false)
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
		def  ctrl_show_design(object)
			variant = params[ :variant]
				tree         = build_tree(object, @myparams[:view_id] , variant)
				content = build_model(object, tree,"scad")
				send_data(content,
		              :filename => object.ident+".scad",
		              :type => "application/scad",
		              :disposition => "attachment") unless content.nil?
		end
		private

		def ctrl_new_datafile(at_object)
			fname= "#{self.class.name}.#{__method__}"
			LOG.debug (fname){"datafile.doc=#{@datafile.document}"}
			@types  = Typesobject.find_for("datafile")
			@checkout_needed = at_object.checkout_needed?
			if @checkout_needed
				check = Check.get_checkout(at_object)
				tr_model = t("ctrl_#{at_object.model_name}")
				unless check.nil?
					flash[:notice] = t(:ctrl_object_already_checkout, :typeobj => tr_model, :ident => at_object.ident, :reason => check.out_reason)
				else
					if current_user.check_automatic
						check = Check.new(object_to_check: at_object, user: current_user, out_reason: t(:ctrl_checkout_auto))
						if check.save
						  #LOG.debug (fname){"check saved=#{check.inspect}"}
							flash[:notice] = t(:ctrl_object_checkout, :typeobj => tr_model, :ident => at_object.ident, :reason => check.out_reason)
						else
							#LOG.debug (fname){"check errors=#{check.errors.inspect}"}
							flash[:error] = t(:ctrl_object_not_checkout, :typeobj => tr_model, :ident => at_object.ident)
							check = nil
						end
					else
						check = nil
						flash[:error] = t(:ctrl_object_not_checkout, :typeobj => tr_model, :ident => at_object.ident)
					end
				end
				respond_to do |format|
					unless check.nil?
						#LOG.debug (fname){"document=#{@document.inspect}"}
						flash[:notice] = t(:ctrl_object_checkout, :typeobj => tr_model, :ident => at_object.ident, :reason => check.out_reason)
						format.html { render :action => :new_datafile, :id => at_object.id }
						format.xml  { head :ok }
					else
						flash[:error] = t(:ctrl_object_not_checkout, :typeobj => tr_model, :ident => at_object.ident)
						format.html { redirect_to(at_object) }
						format.xml  { head :ok }
					end
				end
			else
				respond_to do |format|
					format.html { render :action => :new_datafile, :id => at_object.id }
					format.xml  { head :ok }
				end
			end
		end


		def ctrl_add_datafile(at_object)
			fname= "#{self.class.name}.#{__method__}"
	    LOG.debug (fname){"params=#{params.inspect}"}
			respond_to do |format|
					#@datafile = at_object.datafiles.build(params[:datafile])
					@datafile=Datafile.new(params[:datafile])
					LOG.debug (fname){"on sauve @datafile=#{@datafile} "}
					st= @datafile.save
					LOG.debug (fname){"@datafile save st=#{st} datafile=#{@datafile.inspect} err=#{@datafile.errors.inspect}"}
					if(st==true)
						#mdl=eval at_object.model_name
						#@datafile.mdl = at_object 
					  at_object.datafiles << @datafile  
						if @datafile.save && at_object.save
							if current_user.check_automatic
								check = Check.get_checkout(at_object)
								unless check.nil?
									check = check.checkIn({:in_reason => t("ctrl_checkin_auto")}, current_user)
									#LOG.debug (fname){"check errors==#{check.errors.inspect}"}
									if check.save
							  		#LOG.debug (fname){"check saved=#{check.inspect}"}
										flash[:notice] = t(:ctrl_object_checkin, :typeobj => t("ctrl_#{at_object.model_name}"), :ident => at_object.ident, :reason => check.in_reason)
									else
										flash[:error] = t(:ctrl_object_not_checkin, :typeobj => t(:ctrl_document), :ident => at_object.ident)
										check = nil
									end
								else
									flash[:error] = t(:ctrl_object_not_checkout, :typeobj => t(:ctrl_document), :ident => at_object.ident)
								end
							end
							format.html { redirect_to(at_object) }
						else
							#LOG.debug (fname){"@datafile not saved"}
							flash[:error] = t(:ctrl_object_not_saved,:typeobj =>t(:ctrl_datafile),:ident=>nil,:msg=>nil)
							@types = Typesobject.find_for("datafile")
							format.html { render :action => :new_datafile, :id => at_object.id   }
						end
					else
						#LOG.debug (fname){"@datafile not saved"}
						flash[:error] = t(:ctrl_object_not_saved,:typeobj =>t(:ctrl_datafile),:ident=>nil,:msg=>nil)
						@types = Typesobject.find_for("datafile")
						format.html { render :action => :new_datafile, :id => at_object.id   }
					end
			end
		end


		def ctrl_duplicate_links(params, obj, user)
	    ret=true
	   	unless params["links"].nil?
				#puts "========================="+params["links"].inspect
				params["links"].each {
					|key, value| 
					#puts "ctrl_duplicate_links:#{key} is #{value}"
					value.each do |lnkid|
						lnk_orig = Link.find(lnkid)
						#puts "=========================lnk_orig="+lnk_orig.inspect
						lnk_new = lnk_orig.duplicate(obj, user)
						#puts "=========================lnk_new="+lnk_new.inspect
						lnk_new.save unless lnk_new.nil?
					end
				}
			end
			ret
		end
		  #
  # controle des vues et de la vue active
  #
  def define_view
  	#puts "#{controller_name}.define_view:begin view=#{@myparams[:view_id]}"
  	# views: liste des vues possibles est utilisee dans la view ruby show
		@views = View.all
		# view_id: id de la vue selectionnee est utilisee dans la view ruby show
		#@myparams[:view_id] = @views.first.id if @myparams[:view_id].nil?
		if @myparams[:view_id].nil?
			if logged_in?
			@myparams[:view_id] = current_user.get_default_view.id
			end
		end
		#puts "#{controller_name}.define_view:end view=#{@myparams[:view_id]}"
	end
  #
  # Creates an HistoryEntry record
  #
  def history_log (event, options={})
    fname= "#{self.class.name}.#{__method__}"
    source = options.delete(:source) || @current_user.login
    #LOG.debug (fname){"history_log:source=#{source}"}
   	#LOG.debug (fname){"history_log:options=#{options}"}
    Ruote::Sylrplm::HistoryEntry.log!(source, event, options)
  end
  
  def get_datas_count
  	ret = {}
    ret[:plm_objects] = {
	      :datafile => Datafile.count,
	      :document => Document.count,
	      :part => Part.count,
	      :project => Project.count,
	      :customer => Customer.count
	    }
   	ret[:collab_objects] = {
      	:forum => Forum.count,
      	:question => Question.count
     	}
    ret[:organization] = {
	      :user => User.count,
	      :role => Role.count,
	      :group => Group.count,
	      :volume => Volume.count
      }
    ret[:parametrization] = {
	      :typesobject => Typesobject.count,
	      :statusobject => Statusobject.count,
	      :relation => Relation.count,
        :definition => Definition.count
      }
    if admin_logged_in?
      ret[:internal_objects] = {
        	:link => Link.count
      		}
    end
    ret
  end
  
  #
  # Returns a new LinkGenerator wrapping the current request.
  #
  def linkgen
    LinkGenerator.new(request)
  end
	def update_accessor(current_user)
    mdl_name = self.model_name
    params[mdl_name][:owner_id]=current_user.id if self.instance_variable_defined?(:@owner_id)
    params[mdl_name][:group_id]=current_user.group_id if self.instance_variable_defined?(:@group_id)
    params[mdl_name][:projowner_id]=current_user.project_id if self.instance_variable_defined?(:@projowner_id)
    #puts "update_accessor:"+params.inspect
  end
	end
end
