#require 'lib/controllers/plm_object_controller_module'
#require 'lib/controllers/plm_init_controller_module'
class ProjectsController < ApplicationController
	include Controllers::PlmObjectControllerModule
	#access_control (Access.find_for_controller(controller_name.classify))
	#before_filter :authorize, :only => [ :show, :edit , :new, :destroy ]
	# GET /projects
	# GET /projects.xml
	# liste de tous les projets
	# les lignes sont tries d'apres le parametre sort
	# les objets sont filtres d'apres le parametre query (requete simple d'egalite
	#   sur tous les attributs)
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

	# GET /projects/1
	# GET /projects/1.xml
	# affichage d'un projet
	# liste des attributs avec leur valeur
	# arbre montrant la structure du projet: le client et les parts
	def show_old
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @object_plm }
		end
	end

	def select_view
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"begin:params=#{params}"}
		if params["commit"].force_encoding("utf-8") == t("root_model_design").force_encoding("utf-8")
			show_design
		else
			show_
			respond_to do |format|
				format.html { render :action => "show" }
				format.xml  { render :xml => @object_plm }
			end
		end
	end

	# GET /projects/new
	# GET /projects/new.xml
	# nouveau projet
	# on definit les listes de valeur pour le type et le statut
	def new
		@object_plm = Project.new(user: current_user)
		@types = Typesobject.get_types("project")
		@types_access    = Typesobject.get_types("project_typeaccess")
		@status= Statusobject.get_status("project", true)
		@users  = User.all
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @object_plm }
		end
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_orig = Project.find(params[:id])
		@object_plm = @object = @object_orig.duplicate(current_user)
		@types    = Typesobject.get_types("project")
		@status   = Statusobject.get_status("project", 2)
		@types_access    = Typesobject.get_types("project_typeaccess")
		@users  = User.all
		respond_to do |format|
			format.html # project/1/new_dup
			format.xml  { render :xml => @object_plm }
		end
	end

	# GET /projects/1/edit
	# modification d'un projet
	def edit
		@object_plm = Project.find_edit(params[:id])
		@types=Typesobject.get_types("project")
		@types_access    = Typesobject.get_types("project_typeaccess")
		@users  = User.all
	end

	# GET /projects/1/edit_lifecycle
	# modification d'un projet
	def edit_lifecycle
		@object_plm = Project.find_edit(params[:id])
	end

	# POST /projects
	# POST /projects.xml
	# creation d'un projet (apres validation du new)
	def create
		@object_plm = Project.new(params[:project])
		@types = Typesobject.get_types("project")
		@types_access = Typesobject.get_types("project_typeaccess")
		@status = Statusobject.get_status("project")
		@users  = User.all
		respond_to do |format|
			if fonct_new_dup?
				object_orig=Project.find(params[:object_orig_id])
			st = @object_plm.create_duplicate(object_orig)
			else
			st = @object_plm.save
			end
			if st
				st = ctrl_duplicate_links(params, @object_plm, current_user)
				flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_project),:ident=>@object_plm.ident)
				params[:id]=@object_plm.id
				show_
				format.html { render :action => "show"}
				format.xml  { render :xml => @object_plm, :status => :created, :location => @object_plm }
			else
				flash[:error] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_project),:ident=>@object_plm.ident, :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @object_plm.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /projects/1
	# PUT /projects/1.xml
	# maj d'un projet (apres validation du edit)
	def update
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Project.find(params[:id])
		@types=Typesobject.get_types("project")
		@types_access    = Typesobject.get_types("project_typeaccess")
		@status= Statusobject.get_status("project")
		@users  = User.all
		@object_plm.update_accessor(current_user)
		if commit_promote?
			ctrl_promote(@object_plm)
		else
			respond_to do |format|
				if @object_plm.update_attributes(params[:project])
					customer_id=params[:project_link][:customer_id]
					LOG.debug(fname){"params[:project_link]=#{params[:project_link]} customer_id=#{customer_id}"}
					unless customer_id.blank?
						customer=Customer.find(customer_id)
						relation=Relation.find_by_name("ask_for")
						link_customer=Link.find_by_father_plmtype_and_father_id_and_child_plmtype_and_child_id_and_relation_id("customer", customer.id,"project",@object_plm.id,relation.id)
						LOG.debug(fname){"link_customer=#{link_customer.inspect}"}
						if link_customer.nil?
						link_customer = Link.new(father: customer, child: @object_plm, relation: relation, user: current_user)
						if link_customer.save
						end
						end
					end
					flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_project),:ident=>@object_plm.ident)
					show_
					format.html { render :action => "show"}
					format.xml  { head :ok }
				else
					flash[:error] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_project),:ident=>@object_plm.ident, :error => @object_plm.errors.full_messages)
					format.html { render :action => "edit" }
					format.xml  { render :xml => @object_plm.errors, :status => :unprocessable_entity }
				end
			end
		end
	end

	def update_lifecycle
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Project.find(params[:id])
		@types_access    = Typesobject.get_types("project_typeaccess")
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
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Project.find(params[:id])
		@types_access    = Typesobject.get_types("project_typeaccess")
		ctrl_update_type @object_plm, params[:object_type]
	end

	# DELETE /projects/1
	# DELETE /projects/1.xml
	def destroy_old
		@object_plm = Project.find(params[:id])
		respond_to do |format|
			unless @object_plm.nil?
				if @object_plm.destroy
					flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_project), :ident => @object_plm.ident)
					format.html { redirect_to(projects_url) }
					format.xml  { head :ok }
				else
					flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_project), :ident => @object_plm.ident)
					index_
					format.html { render :action => "index" }
					format.xml  { render :xml => @object_plm.errors, :status => :unprocessable_entity }
				end
			else
				flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_project), :ident => @object_plm.ident)
			end
		end

	end

	def promote_by_menu
		promote_
	end

	def promote_by_action
		promote_
	end

	def promote_
		ctrl_promote(Project,false)
	end

	def demote
		ctrl_demote(Project,false)
	end

	def new_forum
		puts 'CustomerController.new_forum:id='+params[:id]
		@object = Project.find(params[:id])
		@types = Typesobject.get_types("forum")
		@status = Statusobject.get_status("forum")
		@relation_id = params[:relation][:forum]

		respond_to do |format|
			flash[:notice] = ""
			@forum = Forum.new(user: current_user)
			@forum.subject = t(:ctrl_subject_forum, :typeobj => t(:ctrl_project), :ident => @object.ident)
			format.html { render :action => :new_forum, :id => @object.id }
			format.xml  { head :ok }
		end
	end

	def add_forum
		@object = Project.find(params[:id])
		ctrl_add_forum(@object)
	end

	def add_docs
		@object_plm = Project.find(params[:id])
		ctrl_add_objects_from_clipboardtes(@object_plm, :document)
	end

	def add_parts
		@object_plm = Project.find(params[:id])
		ctrl_add_objects_from_clipboardtes(@object_plm, :part)
	end

	#
	# preparation du datafile a associer
	#
	def new_datafile
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Project.find(params[:id])
		@datafile = Datafile.new({:user => current_user, :theproject => @object_plm})
		ctrl_new_datafile(@object_plm)
	end

	#
	# creation du datafile et association et liberation si besoin
	#
	def add_datafile
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Project.find(params[:id])
		ctrl_add_datafile(@object_plm)
	end

	def show_design
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		#LOG.debug(fname){"myparams=#{@myparams.inspect}"}
		project = Project.find(params[:id])
		ctrl_show_design(project, params[:type_model_id])
	end

	private

	def show_
		fname= "#{self.class.name}.#{__method__}"
		define_view
		@object_plm = Project.find(params[:id])
		@object_plms=@object_plm.documents
		@object_plms=@object_plm.parts
		@object_plms=@object_plm.customers_up
		flash[:error] = "" if flash[:error].nil?
		if @clipboard.get('document').count>0 && @object_plm.relations(:document).count==0
			flash[:error] += t(:ctrl_show_no_relation,:father_plmtype => t(:ctrl_project),:child_plmtype => t(:ctrl_document))
		end
		if @clipboard.get('part').count>0 && @object_plm.relations(:part).count==0
			flash[:error] += t(:ctrl_show_no_relation,:father_plmtype => t(:ctrl_project),:child_plmtype => t(:ctrl_part))
		end
		#if @clipboard.get('user').count>0 && @object_plm.relations(:user).count==0
		#	flash[:error] += t(:ctrl_show_no_relation,:father_plmtype => t(:ctrl_project),:child_plmtype => t(:ctrl_user))
		#end
		@tree         						= build_tree(@object_plm, @myparams[:view_id], nil, 2)
		@tree_up      						= build_tree_up(@object_plm, @myparams[:view_id] )
		@object_plm = @object_plm
	end

	def index_
		@object_plms = Project.find_paginate({:user=> current_user, :filter_types => params[:filter_types],:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
	end

end
