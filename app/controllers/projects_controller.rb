#require 'lib/controllers/plm_object_controller_module'
#require 'lib/controllers/plm_init_controller_module'
class ProjectsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  include Controllers::PlmInitControllerModule
  before_filter :check_init, :only=>[:new]
  access_control (Access.find_for_controller(controller_class_name()))

  #before_filter :authorize, :only => [ :show, :edit , :new, :destroy ]

  # GET /projects
  # GET /projects.xml
  # liste de tous les projets
  # les lignes sont tries d'apres le parametre sort
  # les objets sont filtres d'apres le parametre query (requete simple d'egalite
  #   sur tous les attributs)
  def index
    @projects = Project.find_paginate({:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
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
    @project = Project.find(params[:id])
    @relations               = Relation.relations_for(@project)
    @tree=create_tree(@project)
    @tree_up=create_tree_up(@project)
    @documents=@project.documents
    @parts=@project.parts
    @customers=@project.customers
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
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @project }
    end
  end

  # GET /projects/new
  # GET /projects/new.xml
  # nouveau projet
  # le owner est attribue avant la saisie, voir Project.create_new
  # on definit les listes de valeur pour le type et le statut
  def new
    @project = Project.create_new(nil, @current_user)
    @types=Project.get_types_project
    @status= Statusobject.find_for("project")
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
    @status= Statusobject.find_for("project")
  end

  # POST /projects
  # POST /projects.xml
  # creation d'un projet (apres validation du new)
  def create
    @project = Project.create_new(params[:project], @current_user)
    @types=Project.get_types_project
    @status= Statusobject.find_for("project")
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
    @status= Statusobject.find_for("project")
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
    @project.destroy
    respond_to do |format|
      flash[:notice] = t(:ctrl_object_deleted,:typeobj =>t(:ctrl_project),:ident=>@project.ident)
      format.html { redirect_to(projects_url) }
      format.xml  { head :ok }
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
    @types=Typesobject.find_for("forum")
    @status= Statusobject.find_for("forum")
    @relation_id = params[:relation][:forum]
    respond_to do |format|
      flash[:notice] = ""
      @forum=Forum.create_new(nil)
      @forum.subject=t(:ctrl_subject_forum,:typeobj =>t(:ctrl_project),:ident=>@object.ident)
      format.html {render :action=>:new_forum, :id=>@object.id }
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
  def check_init_objects
    ret =""
    
    #pour debug: forcer la reconstruction des access
    ya_acces=Access.count
    if ya_acces == 0
      ret +="Creation access<br>"
      st=Access.init
      st=true
      if st
        ret +="Acces  crees<br>"
      else
        ret +="ERREUR:Acces non crees completement<br>"
      end
    end
    puts 'main_controller.index:ya_acces='+ya_acces.to_s+":"+ret
    ret=""
    @types_document=Typesobject.find_for('document')
    if @types_document.size==0
      ret +="Pas de types de documents<br>"
    end
    @types_part=Typesobject.find_for('part')
    if @types_part.size==0
      ret +="Pas de types d articles<br>"
    end
    @types_project=Typesobject.find_for('project')
    if @types_project.size==0
      ret +="Pas de types de projets<br>"
    end
    @types_customer=Typesobject.find_for('customer')
    if @types_customer.size==0
      ret +="Pas de types de clients<br>"
    end
    @types_forum=Typesobject.find_for('forum')
    if @types_forum.size==0
      ret +="Pas de types de forums<br>"
    end
    
    @status_document= Statusobject.find_for("document")
    if @status_document.size==0
      ret +="Pas de statuts de documents<br>"
    end
    @status_part= Statusobject.find_for("part")
    if @status_part.size==0
      ret +="Pas de statuts d articles<br>"
    end
    @status_project= Statusobject.find_for("project")
    if @status_project.size==0
      ret +="Pas de statuts de projets<br>"
    end
    @status_customer= Statusobject.find_for("customer")
    if @status_customer.size==0
      ret +="Pas de statuts de clients<br>"
    end
    @status_forum= Statusobject.find_for("forum")
    if @status_forum.size==0
      ret +="Pas de statuts de forums<br>"
    end
    ret
  end
  
  def check_init
    ret=check_init_objects
    if ret != ""
      puts 'application_controller.check_init:message='+ret
      flash[:notice]=t(:ctrl_init_to_do)
      respond_to do |format|
        format.html{redirect_to :controller=>"main" , :action => "init_objects"} # init.html.erb
      end
    end
  end
  
  #appelle par main_controller.init_objects
  def create_domain(domain)
    puts "plm_init_controller.create_domain:"+domain
    dirname=SYLRPLM::DIR_DOMAINS+domain+'/*.yml'
    puts "plm_init_controller.create_domain:"+dirname
    Dir.glob(dirname).each do |file|
      dirfile=SYLRPLM::DIR_DOMAINS+domain
      puts "plm_init_controller.create_domain:dirfile="+dirfile+" file="+File.basename(file, '.*')
      Fixtures.create_fixtures(dirfile, File.basename(file, '.*'))
    end
  end
  
  #appelle par main_controller.init_objects
  def create_admin
    puts "plm_init_controller.create_admin:"
    dirname=SYLRPLM::DIR_ADMIN+'*.yml'
    puts "plm_init_controller.create_admin:"+dirname
    Dir.glob(dirname).each do |file|
      dirfile=SYLRPLM::DIR_ADMIN
      puts "plm_init_controller.create_admin:dirfile="+dirfile+" file="+File.basename(file, '.*')
      Fixtures.create_fixtures(dirfile, File.basename(file, '.*'))
    end
  end
  
  #renvoie la liste des domaines pour le chargement initial
  #appelle par main_controller.init_objects
  def get_domains
    dirname=SYLRPLM::DIR_DOMAINS+'*'
    ret=""
    Dir.glob(dirname).each do |dir|
      ret<<"<option>"<<File.basename(dir, '.*')<<"</option>"
    end
    puts "plm_init_controller.get_domains:"+dirname+"="+ret
    ret
  end
  
  #appelle par main_controller.init_objects
  #maj le volume de depart id=1 defini dans le fichier db/fixtures/volume.yml et cree par create_domain 
  def update_admin(dir)
    puts "plm_init_controller.update_first_volume:dir="+dir
    vol=Volume.find_first
    puts "plm_init_controller.update_first_volume:volume="+vol.inspect
    vol.update_attributes(:directory=>dir)
    User.find_all.each do |auser|
      auser.volume=vol
      auser.password=auser.login
      auser.save
      puts "plm_init_controller.update_first_volume:user="+auser.inspect
    end
  end
 
  #methode: creation de 'arbre du projet
  def create_tree(obj)
    tree = Tree.new({:js_name=>"tree_down", :label=>t(:ctrl_object_explorer,:typeobj =>t(:ctrl_project)),:open => true})
    #cnode=tree_project(obj)
    #tree << cnode
    session[:tree_object]=obj
    follow_tree_project(tree, obj)
    tree
  end

  def create_tree_up(obj)
    tree = Tree.new({:js_name=>"tree_up", :label=>t(:ctrl_object_referencer,:typeobj =>t(:ctrl_project)),:open => true})
    #cnode=tree_project(obj)
    #tree << cnode
    session[:tree_object]=obj
    follow_tree_up_project(tree, obj)
    tree
  end 
end
