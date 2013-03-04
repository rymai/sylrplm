#require 'lib/controllers/plm_object_controller_module'
#require 'lib/controllers/plm_init_controller_module'
class ProjectsController < ApplicationController
	include Controllers::PlmObjectControllerModule
	before_filter :check_init, :only=>[:new]
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
		show_
		respond_to do |format|
			format.html { render :action => "show" }
			format.xml  { render :xml => @project }
		end
	end

	def show_
		fname= "#{controller_class_name}.#{__method__}"
		define_view
		@project = Project.find(params[:id])
		@relations               = Relation.relations_for(@project)
		@documents=@project.documents
		@parts=@project.parts
		@customers=@project.customers_up
		flash[:notice] = "" if flash[:notice].nil?
		if @favori.get('document').count>0 && @relations["document"].count==0
			flash[:notice] += t(:ctrl_show_no_relation,:father_plmtype => t(:ctrl_project),:child_plmtype => t(:ctrl_document))
		end
		if @favori.get('part').count>0 && @relations["part"].count==0
			flash[:notice] += t(:ctrl_show_no_relation,:father_plmtype => t(:ctrl_project),:child_plmtype => t(:ctrl_part))
		end
		if @favori.get('user').count>0 && @relations["user"].count==0
			flash[:notice] += t(:ctrl_show_no_relation,:father_plmtype => t(:ctrl_project),:child_plmtype => t(:ctrl_user))
		end
		@tree         						= build_tree(@project, @myparams[:view_id], nil, 2)
		@tree_up      						= build_tree_up(@project, @myparams[:view_id] )
	end

	# GET /projects/new
	# GET /projects/new.xml
	# nouveau projet
	# on definit les listes de valeur pour le type et le statut
	def new
		@project = Project.new(user: @current_user)
		@types = Project.get_types_project
		@types_access    = Typesobject.get_types("project_typeaccess")
		@status= Statusobject.find_for("project", true)
		@users  = User.all
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @project }
		end
	end

	# GET /projects/1/edit
	# modification d'un projet
	def edit
		@project = Project.find_edit(params[:id])
		@types=Project.get_types_project
		@types_access    = Typesobject.get_types("project_typeaccess")
		@status= Statusobject.find_for("project")
		@users  = User.all
	end

	# POST /projects
	# POST /projects.xml
	# creation d'un projet (apres validation du new)
	def create
		@project = Project.new(params[:project].merge(user: @current_user))
		@types=Project.get_types_project
		@types_access    = Typesobject.get_types("project_typeaccess")
		@status= Statusobject.find_for("project")
		@users  = User.all
		respond_to do |format|
			if @project.save
				flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_project),:ident=>@project.ident)
				format.html { redirect_to(@project) }
				format.xml  { render :xml => @project, :status => :created, :location => @project }
			else
				flash[:notice] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_project),:ident=>@project.ident, :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /projects/1
	# PUT /projects/1.xml
	# maj d'un projet (apres validation du edit)
	def update
		@project = Project.find(params[:id])
		@types=Project.get_types_project
		@types_access    = Typesobject.get_types("project_typeaccess")
		@status= Statusobject.find_for("project")
		@users  = User.all
		@project.update_accessor(current_user)
		respond_to do |format|
			if @project.update_attributes(params[:project])
				flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_project),:ident=>@project.ident)
				format.html { redirect_to(@project) }
				format.xml  { head :ok }
			else
				flash[:notice] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_project),:ident=>@project.ident)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
			end
		end
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
					flash[:notice] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_project), :ident => @project.ident)
					index_
					format.html { render :action => "index" }
					format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
				end
			else
				flash[:notice] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_project), :ident => @project.ident)
			end
		end

	end

	def promote
		ctrl_promote(Project,false)
	end

	def demote
		ctrl_demote(Project,false)
	end

	def new_forum
		puts 'CustomerController.new_forum:id='+params[:id]
		@object = Project.find(params[:id])
		@types = Typesobject.find_for("forum")
		@status = Statusobject.find_for("forum")
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

	def add_users
		@project = Project.find(params[:id])
		ctrl_add_objects_from_favorites(@project, :user)
	end

	def empty_favori
		puts "#{self.class.name}.#{__method__}:#{params.inspect}"
		empty_favori_by_type(get_model_type(params))
	end
	private

	def index_
		@projects = Project.find_paginate({:user=> current_user,:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
	end

end
