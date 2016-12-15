class LinksController < ApplicationController
	include Controllers::PlmObjectController
	access_control(Access.find_for_controller(controller_name.classify))

	# GET /links
	# GET /links.xml
	def index
		@links = Link.find_paginate({ :user => current_user, :filter_types => params[:filter_types],:page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @links }
		end
	end

	def reset
		Link.reset
		respond_to do |format|
			format.html { redirect_to(links_url) }
			format.xml  { render :xml => @links }
		end
	end

	# GET /links/1
	# GET /links/1.xml
	def show
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @link }
		end
	end
	def show_
		@link = Link.find(params[:id])
	end
	# GET /links/new
	# GET /links/new.xml
	def new
		@link = Link.new
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @link }
		end
	end

	# GET /links/1/edit
	def edit
		@link = Link.find(params[:id])
	end

	# GET /links/1/edit_in_tree
	def edit_in_tree
		fname= "#{self.class.name}.#{__method__}"
		#LOG.info(fname){"params=#{params.inspect}"}
		@link = Link.find(params[:id])
		LOG.info(fname){"type_values=#{@link.type_values} rel;type.values=#{@link.relation.typesobject.fields}"}
		if(@link.type_values).blank?
		@link.type_values=@link.relation.typesobject.type_values
		end
		@object_in_explorer = PlmServices.get_object(params[:object_model], params[:object_id])
		@root = PlmServices.get_object(params[:root_model], params[:root_id])
		#LOG.info(fname){"link=#{@link}"}
		#LOG.info(fname){"owner=#{(@link.owner.nil? ? "no owner" : @link.owner)}"}
		#LOG.info(fname){"link effectivities=#{@link.links_effectivities}"}
		#LOG.info(fname){"effectivities=#{@link.effectivities}"}
		#LOG.info(fname){"effectivities_mdlid=#{@link.effectivities_mdlid}"}
		#LOG.info(fname){"object_in_explorer=#{@object_in_explorer}"}
		#LOG.info(fname){"root=#{@root}"}
	end

	# POST /links
	# POST /links.xml
	def create
		@link = Link.new(params[:link])
		@link.def_user(current_user)
		respond_to do |format|
		#@link.type_values=params[:link][:values].to_json unless params[:link][:values].nil?
			if @link.save
				flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_link), :ident => @link.ident)
				params[:id]=@link.id
				show_
				format.html { render :action => "show" }
				format.xml  { render :xml => @link, :status => :created, :location => @link }
			else
				flash[:error] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_link), :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @link.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /links/1
	# PUT /links/1.xml
	def update_in_tree
		fname = "#{self.class.name}.#{__method__}"
		#LOG.info(fname) { "params: #{params}" }
		@link = Link.find(params[:id])
		##########@link.update_accessor(current_user)
		@object_in_explorer = PlmServices.get_object(params[:object_model], params[:object_id])
		@root = PlmServices.get_object(params[:root_model], params[:root_id])
		err = false
		respond_to do |format|
			#values = OpenWFE::Json::from_json(params[:link][:values])
			#LOG.info(fname) { "values: #{values}" }
			#########update_att=@link.update_attributes(params[:link])
			update_att = @link.update_link(current_user,params[:link])
			#LOG.info(fname) { "update_att: #{update_att} @link.errors=#{@link.errors.inspect}" }
			@link.errors.clear if update_att
			update_eff = update_effectivities(@link, params[:effectivities])
			#LOG.info(fname) { "update_eff: #{update_eff} @link.errors=#{@link.errors.inspect}" }
			if update_att && update_eff
				LOG.info(fname) { "ok:effectivities: #{params[:effectivities]}" }
				flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_link), :ident => @link.ident)
				format.html { render action: "edit_in_tree" }
				format.xml  { head :ok }
			else
				strerr="ko:update_att=#{update_att} update_eff=#{update_eff} effectivities: #{params[:effectivities]}"
				LOG.info(fname) { strerr}
				# lien non modifie
				flash[:error] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_link),:ident=>@link.ident, :error=>strerr)
				format.html { render action: "edit_in_tree" }
				format.xml  { render xml: @link.errors, status: :unprocessable_entity }
			end
		end
	end

	def update
		fname = "#{self.class.name}.#{__method__}"
		LOG.info(fname) { "params=#{params}" }
		@link = Link.find(params[:id])
		@link.update_accessor(current_user)
		respond_to do |format|
			# values = OpenWFE::Json::from_json(params[:link][:values])
			# LOG.info(fname) { "values=#{values}" }
			if @link.update_attributes(params[:link])
				flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_link), :ident => @link.ident)
				show_
				format.html { render :action => "show" }
				format.xml  { head :ok }
			else
				# lien non modifie
				flash[:error] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_link),:ident=>@link.ident)
				format.html { render action: "edit" }
				format.xml  { render xml: @link.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /links/1
	# DELETE /links/1.xml
	def destroy
		LOG.info("#{self.class.name}.#{__method__}") { "params=#{params}" }
		@link = Link.find(params[:id])
		if @link.destroy
			flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_link), :ident => @link.ident)
		else
			flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_link), :ident => @link.ident)
		end
		respond_to do |format|
			format.html { redirect_to(links_url) }
			format.xml  { head :ok }
		end
	end

	# DELETE /links/1
	# DELETE /links/1.xml
	def remove_link
		fname = "#{self.class.name}.#{__method__}"
		#LOG.info("#{self.class.name}.#{__method__}") { "params=#{params}" }
		@link = Link.find(params[:id])
		@link.destroy
		respond_to do |format|
		  LOG.debug(fname) {"session[:tree_object] =#{session[:tree_object]}"}
			format.html { redirect_to(session[:tree_object].nil? ? links_url : session[:tree_object]) }
			format.xml  { head :ok }
		end
	end

	private

	def update_effectivities(link, effectivities)
		fname="#{self.class.name}.#{__method__}"
		LOG.info(fname) { "link=#{link} effectivities=#{effectivities}" }
		effectivities = Array(effectivities)
		return true if effectivities.empty?
		ret = false
		if relation = Relation.find_by_name(::Link::LINKNAME_LINK_EFF)
			LOG.info(fname) { "relation link_effectivity ok=#{relation}" }
			# menage des autres effectivites
			link.clean_effectivities(effectivities)
			flash[:notice]=""
			effectivities.each do |effectivity|
				if effectivity = PlmServices.get_object_by_mdlid(effectivity)
					#LOG.info(fname) { "effectivity: #{effectivity}" }
					link_eff = Link.new(father: link, child: effectivity, relation: relation, user: current_user)
					if link_eff.save
						ctrltype = t("ctrl_#{effectivity.modelname}")
						flash[:notice] << t(:ctrl_object_added, typeobj: ctrltype, ident: effectivity.ident, relation: relation.ident, msg: "ctrl_link_#{link_eff.ident}")
					else
						# lien link-effectivite non sauve
						ret = true
					end
				end
			end
		else
			LOG.info(fname) { "relation link_effectivity ko" }
			# relation link_effectivity non trouvee
			ret = true
		end

		ret
	end

end
