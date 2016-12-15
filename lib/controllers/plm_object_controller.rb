require_dependency 'ruote/sylrplm/sylrplm'
require_dependency 'controllers/controllers'

module Controllers
	module PlmObjectController

		def export
			fname="#{self.class.name}.#{__method__}"
			LOG.info(fname) { "params=#{params.inspect}" }
			define_table
			LOG.info(fname) { "table=#{@UI_TABLE.ident}" }unless @UI_TABLE.nil?
			#ctrl=eval "::"+params[:controller].to_s.camelize
			ctrl=get_model_from_controller
			@object_plms = ctrl.find_paginate({ :user=> current_user, :filter_types => params[:filter_types], :query => params[:query], :sort => params[:sort], :nb_items =>30000})
		error=nil
			#
			# show_file: inline without a tool
			#
			content = export_table @UI_TABLE
		LOG.info(fname) { "content=#{content.length}" }
			unless content.blank?
				# send_data inline
				filename="#{params[:controller]}_#{params[:action]}.csv"
			error = ctrl_send_data(content, filename, "application/text", "inline")
			else
				error = "Content is empty"
			end
			LOG.info(fname) { "error=#{error}" }
			#respond_to do |format|
				#url=url_for({:controller=>params[:controller], :action=>:index})
				#unless error.nil?
					#format.html { redirect_to(url) }
				#else
					#format.html { redirect_to(url) }
				#end
			#end
		end

		def add_link_objects
			fname="#{self.class.name}.#{__method__}"
			LOG.info(fname) { "params=#{params.inspect}" }
			object=::PlmServices.get_object(get_model_type(params), params[:id])
			::Typesobject::MODELS_PLM.each do |plmtype|
			params.each do |key,value|
				if(key.index("link_")==0)
					unless params[key]["#{plmtype}_id"].blank?
						LOG.info(fname) { "child:#{plmtype}.#{params[key]["#{plmtype}_id"]}" }
						child=::PlmServices.get_object(plmtype, params[key]["#{plmtype}_id"])
						relation=::PlmServices.get_object("relation", params[:relation_id])
						lnk=Link.new(father: object, child: child, relation: relation, user: current_user)
						st=lnk.save
					end
				end
			end
			end
			respond_to do |format|
				#format.html { render :controller => params[:controller], :action => "show", :id =>  params[:id]}
				format.html { redirect_to object}
          format.xml  { head :ok }
		end
		end

		def add_objects
			fname="#{self.class.name}.#{__method__}"
			LOG.info() { "params=#{params.inspect}" }
			obj = PlmServices.get_object(params[:modelname],params[:id])
			flash = {}
			flash[:notice] = ""
			flash[:error] = ""
			LOG.info() { "appel ctrl_add_objects_from_clipboard" }
			flash = ctrl_add_objects_from_clipboard(obj, nil, flash)
		end

		def add_clipboard
	  		fname="#{self.class.name}.#{__method__}"
			LOG.info(fname) { "params=#{params.inspect}" }
			model = get_model(params)
			modelname=get_model_type(params)
			obj = model.find(params[:id])
			LOG.info(fname) { "clipboard(#{modelname})=#{@clipboard.get(modelname).count}" }
			@clipboard.add(obj)
			LOG.info(fname) { "clipboard(#{modelname})=#{@clipboard.get(modelname).count}" }
			LOG.info(fname) { "apres index_ " }
			#index_
			respond_to do |format|
				LOG.info(fname) { "format=#{request.format}"}
				#format.html { render :action => :index}
				format.js { render('shared/refresh_clipboards') }
			end
		end

		def empty_clipboard
			fname="#{self.class.name}.#{__method__}"
			LOG.info(fname) { "params=#{params}}" }
			modelname=get_model_type(params)
			LOG.info(fname) { "clipboard #{modelname} avant=#{@clipboard.get(modelname).count}" }
			empty_clipboard_by_type(modelname)
			LOG.info(fname) { "clipboard #{modelname} apres=#{@clipboard.get(modelname).count}" }
			#index_
			LOG.info(fname) { "format=#{request.format}"}
			respond_to do |format|
				#format.html { render :action => :index}
				format.js { render 'shared/refresh_clipboards' }
				format.json { render 'shared/refresh_clipboards' }
			end
		end

		def ctrl_add_forum(object)
			fname = "#{self.class.name}.#{__method__}"
			LOG.info(fname) { "ctrl_add_forum: params=#{params.inspect}" }
			#LOG.info(fname) { "ctrl_add_forum: object=#{object.inspect} " }
			#LOG.info(fname) { "ctrl_add_forum: typesobject=#{object.typesobject.inspect}" }
			relation = if params["relation_id"].empty?
				forum_type = Typesobject.find(params[:forum][:typesobject_id])
				LOG.info(fname) { "ctrl_add_forum: object.typesobject.id=#{object.typesobject} forum_type=#{forum_type}" }
				Relation.by_types(object.modelname, "forum", object.typesobject.id, forum_type.id)
			else
				LOG.info(fname) { "ctrl_add_forum: relation_id=#{params["relation_id"]}" }
				Relation.find(params["relation_id"])
			end
			error = false
			respond_to do |format|
				flash[:notice] = ""
				@forum = Forum.new(params[:forum].merge(user: current_user))
				@forum.owner = current_user
				if @forum.save
					args={}
					args[:forum]=@forum
					args[:user]=current_user
					args[:message]=params[:message]
					args[:forum_id]=@forum.id
					item = ForumItem.new(args)
					if item.save
						LOG.info(fname) { "ctrl_add_forum: item is saved:#{item}" }
						if relation.nil?
							LOG.info(fname) { "ctrl_add_forum: relation is nil" }
							flash[:notice] << t(:ctrl_object_not_created,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>"no relation",:msg=>nil)
							@forum.destroy
							error = true
						else
							LOG.info(fname) { "ctrl_add_forum: relation is ok:#{relation}" }
							link = Link.new(father: object, child: @forum, relation: relation, user: current_user)
							if link.save
								LOG.info(fname) { "ctrl_add_forum: link is saved:#{link}" }
								flash[:notice] << t(:ctrl_object_added,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation.ident,:msg=>nil)
							else
								LOG.info(fname) { "ctrl_add_forum: link is not saved:#{link}" }
								msg=link.errors.full_messages
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
						LOG.info(fname) { "ctrl_add_forum: item is not saved:#{item}" }
						msg=item.errors.full_messages
						flash[:notice] << t(:ctrl_object_not_created, :typeobj =>t(:ctrl_forum_item),:msg=>msg)
						@forum.destroy
						error = true
					end
				else
					LOG.info(fname) { "ctrl_add_forum: forum is not saved:#{@forum}" }
					flash[:notice] << t(:ctrl_object_not_saved,:typeobj =>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation.ident,:msg=>nil)
					error = true
				end
				if error
					@types = Typesobject.get_types("forum")
					@status = Statusobject.get_status("forum")
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
			fname="#{self.class.name}.#{__method__}:"
			ret = case params[:controller]
			when "checks" then params[:controller].chop
			when "customers" then params[:controller].chop
			when "datafiles" then params[:controller].chop
			when "definitions" then params[:controller].chop
			when "documents" then params[:controller].chop
			when "links" then params[:controller].chop
			when "notifications" then params[:controller].chop
			when "parts" then params[:controller].chop
			when "processes" then "process"
			when "projects" then params[:controller].chop
			when "relations" then params[:controller].chop
			when "statusobjects" then params[:controller].chop
			when "typesobjects" then params[:controller].chop
			when "users" then params[:controller].chop
			when "volumes" then params[:controller].chop
			else params[:controller]
			end
			LOG.debug(fname) {"#{params[:controller]}=#{ret}"}
			ret
		end

		def get_controller_from_model_type(model_type)
			# ajouter le 's' de fin
			# part devient parts
			model_type.to_s+"s"
		end

		def get_model(params)
			fname="#{self.class.name}.#{__method__}:"
			# parts devient Part
			LOG.debug(fname) {"params=#{params.inspect}"}
			eval get_model_type(params).capitalize
		end

		def get_modelname(model)
			fname="#{self.class.name}.#{__method__}:"
			# Part devient part
			ret=model.name.downcase
			LOG.debug(fname) {"model=#{model} get_modelname=#{ret}"}
			ret
		end

		def get_model_from_controller
			fname="#{self.class.name}.#{__method__}:"
			#PartsController devient Part
			pos=self.class.name.index("sController")
			modelname=self.class.name[0,pos]
			ret=eval modelname
			LOG.debug(fname) {"modelname=#{modelname} model=#{ret}"}
			ret
		end

		def get_themes(default)
			fname="#{self.class.name}.#{__method__}:"
			#renvoie la liste des themes
			dirname = "#{Rails.root}/public/stylesheets/*"
			ret = ""
			Dir[dirname].each do |dir|
				LOG.debug(fname) {"get_themes; dir=#{dir} "}
				if File.directory?(dir)
					theme = File.basename(dir, '.*')
					if theme == default
						ret << "<option selected=\"selected\">#{theme}</option>"
					else
						ret << "<option>#{theme}</option>"
					end
				end
			end
			LOG.debug(fname) {"get_themes; ret=#{ret} "}
			ret.html_safe
		end

		def get_languages
			fname="#{self.class.name}.#{__method__}:"
			#renvoie la liste des langues
			dirname = "#{Rails.root}/config/locales/*.yml"
			ret = []
			Dir[dirname].each do |dir|
				lng = File.basename(dir, '.*')
				ret << [t("language_"+lng), lng]
			end
			LOG.debug(fname) {"#{dirname}=#{ret}"}
			ret
		end

		def html_models_and_columns(default = nil)
			fname="#{self.class.name}.#{__method__}:"
			lst=[]
			Dir.new("#{Rails.root}/app/models").entries.each do |model|
				unless %w[. .. _obsolete _old Copy].include?(model)
					model = model.camelize.gsub('.rb', '')
					begin
						LOG.debug(fname) {"#{model}=#{model}"}
						model.constantize.columns.each do |col|
						acol=["#{model}.#{col.name}","#{model}.#{col.name}"]
						LOG.debug(fname){"msg col=#{col.name} : #{acol}"}
						lst<<acol unless %w[created_at updated_at owner].include?(col.name)
					end
					rescue Exception => e
						msg="ERROR: on model #{model}#{e}"
						LOG.error(fname){msg}
					end
					# do nothing
				end
			end
			#ret=get_html_options(lst.sort, default)
			ret=lst
			LOG.debug(fname){"lst=#{lst.size} "}
			ret
		end

		def  get_html_options_obsolete(lst, default, translate=false)
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

		def  ctrl_update_type(plm_object, type_id)
			fname= "#{self.class.name}.#{__method__}"
			type=Typesobject.find(type_id)
			LOG.debug(fname){"type to activate=#{type} on #{plm_object}"}
			modifs=plm_object.modify_type(type)
			flash[:info]=""
			modifs.each do |modif|
				flash[:info] << modif+"<br/>"
			end
			@types = Typesobject.get_types(plm_object.modelname)
			render :update do |page|
				LOG.debug(fname){"render page replace:type=#{plm_object.typesobject}"}
				page.replace_html("edit_object",
				:partial => "shared/edit_object",
				:locals=>{:fonct=>"edit", :plm_object=>plm_object} )
			end
		end

		def  ctrl_update_forobject(plm_object, forobject)
			fname= "#{self.class.name}.#{__method__}"
			LOG.debug(fname){"update=#{plm_object} with #{forobject}"}
			@types = plm_object.others
			plm_object.forobject=forobject
			render :update do |page|
				page.replace_html("edit_object",
				:partial => "shared/edit_object",
				:locals=>{:fonct=>"edit", :plm_object=>plm_object} )
			end
		end

		def ctrl_show_design(object, type_model_id)
			fname= "#{self.class.name}.#{__method__}"
			#LOG.debug(fname){"object=#{object.ident} type_model=#{type_model_id}"}
			type_model = Typesobject.find(type_model_id) unless type_model_id.nil?
			unless type_model.nil?
				tree    = build_tree(object, @myparams[:view_id] , params[:variant])
				content = build_model_tree(object, tree, type_model)
				#LOG.debug(fname){"content=#{content}"}
				unless content["content"].nil?
					if content["content"].respond_to?(:path)
						send_file(content["content"].path,
							:filename => content["filename"],
							:type => content["content_type"],
							:disposition => "attachment")
					else
						send_data(content["content"],
#			              :filename => "#{object.ident}.#{type_model.name}",
#			              :type => "application/#{type_model.name}",
						:filename => "#{content["filename"]}",
						:type => "#{content["content_type"]}",
						:disposition => "attachment")
					end
				else
					respond_to do |format|
						flash[:error] = "Error during model generation:#{object.errors.inspect}"
						LOG.debug(fname){"flash=#{flash[:error]} err=#{object.errors.inspect}"}
						format.html { redirect_to(object) }
						format.html { render :action => "show"  }
						format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
					end
				end
			else
				respond_to do |format|
					flash[:error] = "Can t generate the model because type is not defined}"
						format.html { render :action => "show"  }
					format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
				end
			end
		end

		private

		def ctrl_new_datafile(at_object)
			fname= "#{self.class.name}.#{__method__}"
			LOG.debug(fname){"ctrl_new_datafile: datafile.doc=#{@datafile.document}"}
			@types  = Typesobject.get_types("datafile")
			@checkout_needed = at_object.checkout_needed?
			if @checkout_needed
				LOG.debug(fname){"ctrl_new_datafile: #{at_object} checkout demande"}
				check = Check.get_checkout(at_object)
				tr_model = t("ctrl_#{at_object.modelname}")
				unless check.nil?
					LOG.debug(fname){"ctrl_new_datafile: #{at_object} check deja realise "}
					flash[:notice] = t(:ctrl_object_already_checkout, :typeobj => tr_model, :ident => at_object.ident, :reason => check.out_reason)
				else
					if current_user.check_automatic
						check = Check.new(object_to_check: at_object, user: current_user, out_reason: t(:ctrl_checkout_auto))
						if check.save
					  		LOG.debug(fname){"ctrl_new_datafile: #{at_object} check saved=#{check.inspect}"}
					 		 flash[:notice] = t(:ctrl_object_checkout, :typeobj => tr_model, :ident => at_object.ident, :reason => check.out_reason)
						else
							LOG.debug(fname){"ctrl_new_datafile: #{at_object} check errors=#{check.errors.full_messages}"}
							flash[:error] = t(:ctrl_object_not_checkout, :typeobj => tr_model, :ident => at_object.ident)
							check = nil
						end
					else
						check = nil
						LOG.debug(fname){"ctrl_new_datafile: #{at_object} check not automatic:check=nil"}
						flash[:error] = t(:ctrl_object_not_checkout, :typeobj => tr_model, :ident => at_object.ident)
					end
				end
				respond_to do |format|
					unless check.nil?
						LOG.debug(fname){"ctrl_new_datafile: #{at_object} , on y va"}
						flash[:notice] = t(:ctrl_object_checkout, :typeobj => tr_model, :ident => at_object.ident, :reason => check.out_reason)
						format.html { render :action => :new_datafile, :id => at_object.id }
						format.xml  { head :ok }
					else
						LOG.debug(fname){"ctrl_new_datafile: #{at_object}"}
						flash[:error] = t(:ctrl_object_not_checkout, :typeobj => tr_model, :ident => at_object.ident)
						#format.html { redirect_to(at_object) }
						show_
						format.html { render :action => :show, :id => at_object.id }
						format.xml  { head :ok }
					end
				end
			else
				LOG.debug(fname){"ctrl_new_datafile: #{at_object} checkout non demande, on y va"}
				respond_to do |format|
					format.html { render :action => :new_datafile, :id => at_object.id }
					format.xml  { head :ok }
				end
			end
		end

		def ctrl_index
			fname= "#{self.class.name}.#{__method__}"
			@object_plm=get_object_plm_from_params(params)
				if @object_plm.nil?
					index_
					LOG.debug(fname){"@object_plms=#{@object_plms}"}
					respond_to do |format|
						format.html # index.html.erb
						format.xml  { render :xml => @object_plms }
					end
				else
					# current object exist : portal
					LOG.debug(fname){"object_plm=#{@object_plm} => portal"}
					params[:id]=@object_plm.id
					show
				end
		end

		def ctrl_add_datafile(at_object)
			fname= "#{self.class.name}.#{__method__}"
			LOG.debug(fname){"ctrl_add_datafile: params=#{params.inspect}"}
			respond_to do |format|
				#@datafile = at_object.datafiles.build(params[:datafile])
				LOG.debug(fname){"ctrl_add_datafile: params[:datafile]=#{params[:datafile]} "}
				@datafile=Datafile.new(params[:datafile].merge({:user=>current_user}))
				@datafile.update_attributes(params[:datafile])
				LOG.debug(fname){"ctrl_add_datafile: on sauve @datafile=#{@datafile} "}
				st= @datafile.save
				LOG.debug(fname){"ctrl_add_datafile: @datafile save st=#{st} datafile=#{@datafile.inspect} err=#{@datafile.errors.full_messages}"}
				if(st==true)
					#mdl=eval at_object.modelname
					#@datafile.mdl = at_object
					at_object.datafiles << @datafile
					if @datafile.save && at_object.save
						if current_user.check_automatic
							check = Check.get_checkout(at_object)
							unless check.nil?
								check = check.checkIn({:in_reason => t("ctrl_checkin_auto")}, current_user)
								#LOG.debug(fname){"check errors==#{check.errors.inspect}"}
								if check.save
						  			#LOG.debug(fname){"check saved=#{check.inspect}"}
						  			flash[:notice] = t(:ctrl_object_checkin, :typeobj => t("ctrl_#{at_object.modelname}"), :ident => at_object.ident, :reason => check.in_reason)
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
						#LOG.debug(fname){"@datafile not saved"}
						flash[:error] = t(:ctrl_object_not_saved,:typeobj =>t(:ctrl_datafile),:ident=>nil,:msg=>nil)
						@types = Typesobject.get_types("datafile")
						format.html { render :action => :new_datafile, :id => at_object.id   }
					end
				else
					#LOG.debug(fname){"@datafile not saved"}
					flash[:error] = t(:ctrl_object_not_saved,:typeobj =>t(:ctrl_datafile),:ident=>nil,:msg=>nil)
					@types = Typesobject.get_types("datafile")
					format.html { render :action => :new_datafile, :id => at_object.id   }
				end
			end
		end

		#
		# duplicate each links from the object
		#
		def ctrl_duplicate_links(params, obj, user)
			fname= "#{self.class.name}.#{__method__}"
			LOG.debug(fname){"ctrl_duplicate_links params=#{params} obj duplique=#{obj}"}
			ret=obj.duplicate_links(params,user)
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
		    LOG.debug(fname){"source=#{source}"}
			ret=Ruote::Sylrplm::HistoryEntry.log!(source, event, options)
			LOG.debug(fname){"ret=#{ret}"}
			LOG.debug(fname){"fields=#{ret.fields}"}
			ret
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
			fname= "#{self.class.name}.#{__method__}"
			mdl_name = self.modelname
		  	params[mdl_name][:owner_id]=current_user.id if self.instance_variable_defined?(:@owner_id)
		  	params[mdl_name][:group_id]=current_user.group_id if self.instance_variable_defined?(:@group_id)
		  	params[mdl_name][:projowner_id]=current_user.project_id if self.instance_variable_defined?(:@projowner_id)
		   LOG.debug(fname) {" params=#{params[mdl_name].inspect}"}
		end


		#
		# execute an action on several objects from index page
		#
		def ctrl_index_execute()
			fname= "#{self.class.name}.#{__method__}"
			LOG.debug(fname){"params=#{params}"}
			LOG.debug(fname){"action_on=#{params["action_on"]}"}
			model=get_model_from_controller
			params["action_on"].each do |id,check|
				#LOG.debug(fname){"id #{id} check=#{check} commit=#{params["commit"]}"}
				if(check.to_i == 1)
					LOG.debug(fname){"id #{id} ok check=#{check} commit=#{params["commit"]} #{t("submit_copy")} #{t("submit_destroy")}"}
					#object = eval "#{model}.find(#{id})"
					object = model.find(id)
					if(params["commit"] == t("submit_copy"))
					#d'apres plm_object_controller add_clipboard
					LOG.debug(fname){"add clipboard #{object}"}
					@clipboard.add(object)
					end
					if(params["commit"] == t("submit_destroy"))
						LOG.debug(fname){"destroy #{object}"}
					object.destroy
					end
				else
					#LOG.debug(fname){"id #{id} ko check=#{check}"}
				end
			end
			ndex_
			respond_to do |format|
				params[:controller]=
				url={:controller=>get_controller_from_model_type(model.name.downcase), :action=>"index"}
				LOG.debug(fname){"ctrl_index_execute:url= #{url}"}
				format.html { redirect_to(url) }
				format.xml  { render :xml => @object_plms[:recordset] }
			end
		end

		#
		# launch a process
		#
		def ctrl_create_process(format, process_name, a_object, value1, value2)
			fname= "#{self.class.name}.#{__method__}"
			if RuoteKit.engine.nil?
				PlmServices.ruote_init
			end
			flash[:notice] =nil
			flash[:error] =nil
			# create a process
			begin
				@definition = Definition.get_by_process_name(process_name, a_object, value1, value2)
				LOG.debug(fname) {"ctrl_create_process: @definition= #{@definition} "}
				wait_for=true
				unless @definition.nil?
					#
					# launch the process
					#
					LOG.debug(fname) {"ctrl_create_process: @definition.uri=#{@definition.uri}"}
			    	fei_wfid = RuoteKit.engine.launch(@definition.uri)
					LOG.debug(fname) {" process lance: fei_wfid(#{fei_wfid}) "}
					#
					# add the object to the clipboard, the next tasks will use it
					#
					@clipboard.add(a_object)
				else
					flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process), :msg => "definition to validate the user not found")
				end
			rescue Exception => e
				LOG.error(fname){"process not launched error="+e.inspect}
				LOG.error(fname){"trace"}
				e.backtrace.each {|x| LOG.error(fname){x}}
				flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process), :msg => "fei not launched error=#{e}")
				LOG.error(fname){"a_object=#{a_object}"}
			end
		end

		def parse_launchitem
			fname= "#{self.class.name}.#{__method__}"
			ct                        = request.content_type.to_s
			# TODO : deal with Atom[Pub]
			# TODO : sec checks !!!
			begin
				return OpenWFE::Xml::launchitem_from_xml(request.body.read) if ct.match(/xml$/)
					return OpenWFE::Json.launchitem_from_h(request.body.read) if ct.match(/json$/)
					rescue Exception          => e
						raise ErrorReply.new(
							"#{e}:failed to parse launchitem from request body", 400)
					end
			# then we have a form...
			if @current_user.nil?
				#syl: no current login, we assume it is ok for all!
				cur_user=User.find_by_name(PlmServices.get_property(:USER_ADMIN))
			else
				cur_user=@current_user
			end
			params[:launch_user]=cur_user
			unless cur_user.nil?
				if definition_id = params[:definition_id]
					# is the user allowed to launch that process [definition] ?
					definition = Definition.find(definition_id)
					raise ErrorReply.new("you are not allowed to launch this process", 403
						) unless cur_user.may_launch?(definition)
					#rails2 params[:definition_url] = definition.local_uri if definition
					params[:definition_uri] = definition.uri if definition
				elsif definition_url = params[:definition_url]
					raise ErrorReply.new("not allowed to launch process definitions from adhoc URIs", 400
						) unless cur_user.may_launch_from_adhoc_uri?
				elsif definition = params[:definition]
					# is the user allowed to launch embedded process definitions ?
					raise ErrorReply.new("not allowed to launch embedded process definitions", 400
						) unless cur_user.may_launch_embedded_process?
				else
					raise ErrorReply.new("failed to parse launchitem from request parameters", 400)
				end
			else
				raise ErrorReply.new("no user to launch the process", 400)
			end
			if fields = params[:fields]
				params[:fields] = ActiveSupport::JSON::decode(fields)
			end
			LOG.error(fname){"params=#{params}"}
			#rails2 ret = OpenWFE::LaunchItem.from_h(params)
			params
		end

		def add_object_to_workitem(object, ar_workitem)
			fname= "#{self.class.name}.#{__method__}"
			LOG.info(fname) {"#{object} #{ar_workitem}"}
			return ar_workitem.add_object(object)
		end

		#
		# used in create method: does the funct is to duplicate an object ?
		#
		def fonct_new_dup?
		  !params[:fonct].blank? && !params[:fonct][:current].blank? && params[:fonct][:current] == "new_dup"
		end

		def ctrl_destroy
		fname= "#{self.class.name}.#{__method__}"
		#"controller"=>"documents", "action"=>"destroy", "id"=>"4"
		mdl=get_model_type(params)
		mdlobj=get_model(params)
		@object = mdlobj.find(params[:id])
		key="ctrl_#{mdl}"
		respond_to do |format|
			unless @object.nil?
				if @object.destroy
					flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(key), :ident => @object.ident)
					url=url_for({:controller=>params[:controller], :action=>:index})
					format.html { redirect_to(url) }
					format.xml  { head :ok }
				else
					flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(key), :ident => @object.ident)
					index_
					format.html { render :action => "index" }
					format.xml  { render :xml => @object.errors, :status => :unprocessable_entity }
				end
			else
				flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_project), :ident => @object.ident)
			end
		end
	end

	def ctrl_send_data(content, filename, content_type, disposition)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"content.length=#{content.length} filename=#{filename} content_type=#{content_type} disposition=#{disposition} "}
		error=nil
		begin
			send_data(content,
	              :filename => filename,
	              :type => content_type,
	              :disposition => disposition)
		rescue Exception => e
			LOG.error " error="+e.inspect
			e.backtrace.each {|x| LOG.error x}
			error = t(:ctrl_object_not_found,:typeobj => t(:ctrl_datafile),  :ident => @datafile.ident)
		end
		error
	end


	end
end