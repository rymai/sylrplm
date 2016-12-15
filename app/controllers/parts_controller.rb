class PartsController < ApplicationController
	include Controllers::PlmObjectController
	respond_to :html, :js, :json
	access_control(Access.find_for_controller(controller_name.classify))
	#
	# GET /parts
	# GET /parts.xml
	def index
		ctrl_index
	end

	def index_execute
		ctrl_index_execute
	end

	def show
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		#  object with his tree if ask
		show_
		# objects
		index_
		respond_to do |format|
			format.html   { render :action => "show" }
			format.xml  { render :xml => @object_plm }
		end
	end

	# GET /parts/1
	# GET /parts/1.xml
	def show_old
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @object_plm }
		end
	end

	def select_view
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		LOG.debug(fname){"#{params["commit"].force_encoding("utf-8")}==? #{t("root_model_design").force_encoding("utf-8")}"}
		if params["commit"].force_encoding("utf-8") == t("root_model_design").force_encoding("utf-8")
			show_design
		else
			show_
			respond_to do |format|
				format.html { render :action => "show" }
				#format.html
				#format.html { redirect_to(@object_plm) }
				format.xml  { render :xml => @object_plm }
			end
		end
	end

	# GET /parts/new
	# GET /parts/new.xml
	def new
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm   = Part.new(user: @current_user)
		@types  = Typesobject.get_types("part")
		@status = Statusobject.get_status("part", 2)
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @object_plm }
		end
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"new_dup: params=#{params.inspect}"}
		@object_orig = Part.find(params[:id])
		@object_plm = @object = @object_orig.duplicate(current_user)
		@types    = Typesobject.get_types("part")
		@status   = Statusobject.get_status("part", 2)
		respond_to do |format|
			format.html # part/1/edit
			format.xml  { render :xml => @object_plm }
		end
	end

	# GET /parts/1/edit
	def edit
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"part edit params=#{params.inspect}"}
		@object_plm   = Part.find_edit(params[:id])
		@types  = Typesobject.get_types("part")
	end

	# GET /parts/1/edit_lifecycle
	def edit_lifecycle
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm   = Part.find_edit(params[:id])
	end

	# POST /parts
	# POST /parts.xml
	def create
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"create: params=#{params.inspect}"}
		@object_plm   = Part.new(params[:part])
		@object_plm.def_user(current_user)
		@types  = Typesobject.get_types("part")
		@status = Statusobject.get_status("part")
		respond_to do |format|
			if fonct_new_dup?
				object_orig=Part.find(params[:object_orig_id])
			st = @object_plm.create_duplicate(object_orig)
			else
			st = @object_plm.save
			end
			if st
				st = ctrl_duplicate_links(params, @object_plm, current_user)
				flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_part),:ident=>@object_plm.ident)
				params[:id]=@object_plm.id
				LOG.debug(fname) {"create type_values=#{@object_plm.type_values.inspect}"} if @object_plm.respond_to? :type_values
				show_
				format.html { render :action => "show"}
				format.xml  { render :xml => @object_plm, :status => :created, :location => @object_plm }
			else
				flash[:error] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_part), :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @object_plm.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /parts/1
	# PUT /parts/1.xml
	def update
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Part.find(params[:id])
		@object_plm.update_accessor(current_user)
		if commit_promote?
			ctrl_promote(@object_plm)
		else
			respond_to do |format|
				st=@object_plm.update_attributes(params[:part])
				LOG.debug(fname){"st update=#{st}"}
				if st
					flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_part),:ident=>@object_plm.ident)
					format.html { redirect_to(@object_plm) }
					format.xml  { head :ok }
				else
					flash[:error] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_part),:ident=>@object_plm.ident, :error => @object_plm.errors.full_messages)
					edit
					format.html { render :action => "edit"}
					format.xml  { render :xml => @object_plm.errors, :status => :unprocessable_entity }
				end
			end
		end
	end

	def update_lifecycle
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Part.find(params[:id])
		if commit_promote?
			ctrl_promote(@object_plm)
		end
		if commit_demote?
			ctrl_demote(@object_plm)
		end
		if commit_revise?
			ctrl_revise(@object_plm)
		end
	end

	#
	# update of edit panel after changing the type
	#
	def update_type
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Part.find(params[:id])
		ctrl_update_type @object_plm, params[:object_type]
	end

	def revise
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		ctrl_revise(Part)
	end

	def add_docs
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Part.find(params[:id])
		ctrl_add_objects_from_clipboard(@object_plm, :document)
	end

	def add_parts
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Part.find(params[:id])
		ctrl_add_objects_from_clipboard(@object_plm, :part)
	end

	def new_forum
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object = Part.find(params[:id])
		@types = Typesobject.get_types("forum")
		@status = Statusobject.get_status("forum")
		@relation_id = params["relation"]["forum"]
		respond_to do |format|
			flash[:notice] = ""
			@forum = Forum.new(user: current_user)
			@forum.subject = t(:ctrl_subject_forum, :typeobj => t(:ctrl_part), :ident => @object.ident)
			format.html { render :action => :new_forum, :id => @object.id }
			format.xml  { head :ok }
		end
	end

	def add_forum
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Part.find(params[:id])
		ctrl_add_forum(@object_plm)
	end

	def promote
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Part.find(params[:id])
		ctrl_promote(@object_plm)
	end

	def demote
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Part.find(params[:id])
		ctrl_demote(@object_plm)
	end

	#
	# preparation du datafile a associer
	#
	def new_datafile
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Part.find(params[:id])
		@datafile = Datafile.new({:user => current_user, :thepart => @object_plm})
		ctrl_new_datafile(@object_plm)
	end

	#
	# creation du datafile et association et liberation si besoin
	#
	def add_datafile
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Part.find(params[:id])
		ctrl_add_datafile(@object_plm)
	end

	def show_design
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		part = Part.find(params[:id])
		ctrl_show_design(part, params[:type_model_id])
	end

	private

	def show_
		fname= "#{self.class.name}.#{__method__}"
		#
		define_view
		#
		prop_name="#{current_user.login}.part_structure"
		prop=PlmServices.get_property( prop_name,"form_values")
		LOG.debug(fname){"prop=#{prop.inspect}"}
		unless prop.nil?
			params[:variant] = prop[:variant] if params[:variant].blank?
			params[:view_id] = prop[:view_id] if params[:view_id].blank?
			params[:all_variants] = prop[:all_variants] if params[:all_variants].blank?
			params[:type_model_id] = prop[:type_model_id] if params[:type_model_id].blank?
		end
		PlmServices.set_property( "form_values",prop_name ,
		{:variant=>params[:variant], :view_id=>params[:view_id], :all_variants=>params[:all_variants], :type_model_id=>params[:type_model_id]})
		#
		@object_plm                    = Part.find(params[:id])
		#rails2 @other_parts = Part.paginate(:page => params[:page], :conditions => ["id != #{@object_plm.id}"], :order => 'ident ASC', :per_page => PlmServices.get_property(:NB_ITEMS_PER_PAGE).to_i)
		@other_parts = Part.where("id != #{@object_plm.id}").order('ident ASC').paginate(:page => params[:page],
		:per_page => PlmServices.get_property(:NB_ITEMS_PER_PAGE).to_i)
		@first_status = Statusobject.get_first(@object_plm)
		all_variant=(params[:all_variants].nil? ? "no" : params[:all_variants])
		if all_variant == "on"
			params[:variant]=nil
		end
		LOG.debug(fname){"----------------build_tree begin"}
		@tree         =build_tree(@object_plm, @myparams[:view_id] , params[:variant])
		@tree_up      = build_tree_up(@object_plm, @myparams[:view_id] )
		LOG.debug(fname){"----------------build_tree end"}
		@object_plm = @object_plm
		LOG.debug(fname){"begin:params=#{params}"}
		#LOG.debug(fname){"taille tree=#{@tree.size}"}
		LOG.debug(fname){"variant=#{@variant}"}
	#LOG.debug(fname){"variant eff=#{@variant.var_effectivities}"} unless @variant.nil?
	#LOG.debug(fname){"end:view=#{View.find(@myparams[:view_id]).to_s}"}
	end

	def index_
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		LOG.debug(fname){"filter_types=#{params[:filter_types]}"}
		@object_plms = Part.find_paginate({ :user=> current_user, :filter_types => params[:filter_types], :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
		LOG.debug(fname){"parts=#{@object_plms.size}"}
	end

end
