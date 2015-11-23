#require 'lib/controllers/plm_object_controller_module'
#require 'lib/controllers/plm_init_controller_module'
class ProjectsController < ApplicationController
	include Controllers::PlmObjectControllerModule
	#access_control (Access.find_for_controller(controller_class_name()))
	#before_filter :authorize, :only => [ :show, :edit , :new, :destroy ]
	# GET /projects
	# GET /projects.xml
	# liste de tous les projets
	# les lignes sont tries d'apres le parametre sort
	# les objets sont filtres d'apres le parametre query (requete simple d'egalite
	#   sur tous les attributs)
	def index
		index_
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @projects[:recordset] }
		end
	end

   def index_execute
		ctrl_index_execute
	end

	# GET /projects/1
	# GET /projects/1.xml
	# affichage d'un projet
	# liste des attributs avec leur valeur
	# arbre montrant la structure du projet: le client et les parts
	def show
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @project }
		end
	end

	def select_view
		fname= "#{controller_class_name}.#{__method__}"
		#LOG.debug (fname){"begin:params=#{params}"}
		if params["commit"].force_encoding("utf-8") == t("root_model_design").force_encoding("utf-8")
			show_design
		else
			show_
			respond_to do |format|
				format.html { render :action => "show" }
				format.xml  { render :xml => @project }
			end
		end
	end

	# GET /projects/new
	# GET /projects/new.xml
	# nouveau projet
	# on definit les listes de valeur pour le type et le statut
	def new
		@project = Project.new(user: current_user)
		@types = Typesobject.get_types("project")
		@types_access    = Typesobject.get_types("project_typeaccess")
		@status= Statusobject.get_status("project", true)
		@users  = User.all
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @project }
		end
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"params=#{params.inspect}"}
		@object_orig = Project.find(params[:id])
		@project = @object = @object_orig.duplicate(current_user)
		@types    = Typesobject.get_types("project")
		@status   = Statusobject.get_status("project", 2)
		@types_access    = Typesobject.get_types("project_typeaccess")
		@users  = User.all
		respond_to do |format|
			format.html # project/1/new_dup
			format.xml  { render :xml => @project }
		end
	end

	# GET /projects/1/edit
	# modification d'un projet
	def edit
		@project = Project.find_edit(params[:id])
		@types=Typesobject.get_types("project")
		@types_access    = Typesobject.get_types("project_typeaccess")
		@users  = User.all
	end

	# GET /projects/1/edit_lifecycle
	# modification d'un projet
	def edit_lifecycle
		@project = Project.find_edit(params[:id])
	end

	# POST /projects
	# POST /projects.xml
	# creation d'un projet (apres validation du new)
	def create
		@project = Project.new(params[:project])
		@types = Typesobject.get_types("project")
		@types_access = Typesobject.get_types("project_typeaccess")
		@status = Statusobject.get_status("project")
		@users  = User.all
		respond_to do |format|
			if fonct_new_dup?
				object_orig=Project.find(params[:object_orig_id])
			st = @project.create_duplicate(object_orig)
			else
			st = @project.save
			end
			if st
				st = ctrl_duplicate_links(params, @project, current_user)
				flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_project),:ident=>@project.ident)
				params[:id]=@project.id
				show_
				format.html { render :action => "show"}
				format.xml  { render :xml => @project, :status => :created, :location => @project }
			else
				flash[:error] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_project),:ident=>@project.ident, :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /projects/1
	# PUT /projects/1.xml
	# maj d'un projet (apres validation du edit)
	def update
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname){"params=#{params.inspect}"}
		@project = Project.find(params[:id])
		@types=Typesobject.get_types("project")
		@types_access    = Typesobject.get_types("project_typeaccess")
		@status= Statusobject.get_status("project")
		@users  = User.all
		@project.update_accessor(current_user)
		if commit_promote?
			ctrl_promote(@project)
		else
			respond_to do |format|
				if @project.update_attributes(params[:project])
					customer_id=params[:project_link][:customer_id]
					LOG.debug (fname){"params[:project_link]=#{params[:project_link]} customer_id=#{customer_id}"}
					unless customer_id.blank?
						customer=Customer.find(customer_id)
						relation=Relation.find_by_name("ask_for")
						link_customer=Link.find_by_father_plmtype_and_father_id_and_child_plmtype_and_child_id_and_relation_id("customer", customer.id,"project",@project.id,relation.id)
						LOG.debug (fname){"link_customer=#{link_customer.inspect}"}
						if link_customer.nil?
						link_customer = Link.new(father: customer, child: @project, relation: relation, user: current_user)
						if link_customer.save
						end
						end
					end
					flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_project),:ident=>@project.ident)
					show_
					format.html { render :action => "show"}
					format.xml  { head :ok }
				else
					flash[:error] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_project),:ident=>@project.ident, :error => @project.errors.full_messages)
					format.html { render :action => "edit" }
					format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
				end
			end
		end
	end

	def update_lifecycle
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname){"params=#{params.inspect}"}
		@project = Project.find(params[:id])
		@types_access    = Typesobject.get_types("project_typeaccess")
		if commit_promote?
			ctrl_promote(@project)
		end
		if commit_demote?
			ctrl_demote(@project)
		end
		if commit_revise?
			ctrl_revise(@project)
		end
	end

	#
	# update of edit panel after changing the type
	#
	def update_type
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"params=#{params.inspect}"}
		@project = Project.find(params[:id])
		@types_access    = Typesobject.get_types("project_typeaccess")
		ctrl_update_type @project, params[:object_type]
	end

	# DELETE /projects/1
	# DELETE /projects/1.xml
	def destroy
		@project = Project.find(params[:id])
		respond_to do |format|
			unless @project.nil?
				if @project.destroy
					flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_project), :ident => @project.ident)
					format.html { redirect_to(projects_url) }
					format.xml  { head :ok }
				else
					flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_project), :ident => @project.ident)
					index_
					format.html { render :action => "index" }
					format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
				end
			else
				flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_project), :ident => @project.ident)
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
		@project = Project.find(params[:id])
		ctrl_add_objects_from_favorites(@project, :document)
	end

	def add_parts
		@project = Project.find(params[:id])
		ctrl_add_objects_from_favorites(@project, :part)
	end

	#
	# preparation du datafile a associer
	#
	def new_datafile
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"params=#{params.inspect}"}
		@project = Project.find(params[:id])
		@datafile = Datafile.new({:user => current_user, :theproject => @project})
		ctrl_new_datafile(@project)
	end

	#
	# creation du datafile et association et liberation si besoin
	#
	def add_datafile
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"params=#{params.inspect}"}
		@project = Project.find(params[:id])
		ctrl_add_datafile(@project)
	end

	def show_design
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"params=#{params.inspect}"}
		#LOG.debug (fname){"myparams=#{@myparams.inspect}"}
		project = Project.find(params[:id])
		ctrl_show_design(project, params[:type_model_id])
	end

	private

	def show_
		fname= "#{controller_class_name}.#{__method__}"
		define_view
		@project = Project.find(params[:id])
		@documents=@project.documents
		@parts=@project.parts
		@customers=@project.customers_up
		flash[:error] = "" if flash[:error].nil?
		if @favori.get('document').count>0 && @project.relations(:document).count==0
			flash[:error] += t(:ctrl_show_no_relation,:father_plmtype => t(:ctrl_project),:child_plmtype => t(:ctrl_document))
		end
		if @favori.get('part').count>0 && @project.relations(:part).count==0
			flash[:error] += t(:ctrl_show_no_relation,:father_plmtype => t(:ctrl_project),:child_plmtype => t(:ctrl_part))
		end
		#if @favori.get('user').count>0 && @project.relations(:user).count==0
		#	flash[:error] += t(:ctrl_show_no_relation,:father_plmtype => t(:ctrl_project),:child_plmtype => t(:ctrl_user))
		#end
		@tree         						= build_tree(@project, @myparams[:view_id], nil, 2)
		@tree_up      						= build_tree_up(@project, @myparams[:view_id] )
		@object_plm = @project
	end

	def index_
		@projects = Project.find_paginate({:user=> current_user, :filter_types => params[:filter_types],:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
	end

end
