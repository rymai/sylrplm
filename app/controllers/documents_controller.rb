class DocumentsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  #droits d'acces suivant le controller et l'action demandee
  #administration par le menu Access
  #access_control (Document.controller_access())
  access_control(Access.find_for_controller(controller_class_name))
  # GET /documents
  # GET /documents.xml
  def index
    index_
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @documents[:recordset] }
    end
  end

  # GET /documents/1
  # GET /documents/1.xml
  def show
    show_
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @document }
    end
  end

  def select_view
    if params["commit"].force_encoding("utf-8") == t("root_model_design").force_encoding("utf-8")
      show_design
    else
      show_
      respond_to do |format|
        format.html { render :action => "show" }
        format.xml  { render :xml => @document }
      end
    end
  end

  # GET /documents/new
  # GET /documents/new.xml
  def new
    fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname) {"params=#{params.inspect}"}
    params={}
    @document = Document.new(:user => current_user)
    @types    = Typesobject.get_types("document")
    @volumes  = Volume.find_all
    @status   = Statusobject.get_status("document", 2)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @document }
    end
  end

  def new_dup
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @object_orig = Document.find(params[:id])
    @document = @object = @object_orig.duplicate(current_user)
    @types    = Typesobject.get_types("document")
    @status   = Statusobject.get_status("document", 2)
    respond_to do |format|
      format.html # document/1/new_dup
      format.xml  { render :xml => @document }
    end
  end

  # GET /documents/1/edit
  def edit
    fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname) {"params=#{params.inspect}"}
    @document = Document.find_edit(params[:id])
    @types    = Typesobject.get_types("document")
  end

  # GET /documents/1/edit_lifecycle
  def edit_lifecycle
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname) {"params=#{params.inspect}"}
    @document = Document.find_edit(params[:id])
  end

  # POST /documents
  # POST /documents.xml
  def create
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname) {"params=#{params.inspect}"}
    #contournement pour faire le upload apres la creation pour avoir la revision dans
    #repository !!!!!!!!!!!!!!
    @document = Document.new(params[:document])
    @types    = Typesobject.get_types("document")
    @status   = Statusobject.get_status("document")
    respond_to do |format|
      if fonct_new_dup?
        object_orig=Document.find(params[:object_orig_id])
      st = @document.create_duplicate(object_orig)
      else
      st = @document.save
      end
      if st
        st = ctrl_duplicate_links(params, @document, current_user)
        #puts "===DocumentsController.create:ok:"+@document.inspect
        flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_document), :ident => @document.ident)
        ###format.html { redirect_to(@document) }
        # tout ceci pour ne pas perdre le flash
        params[:id]=@document.id
        show_
        format.html { render :action => "show"}
        format.xml  { render :xml => @document, :status => :created, :location => @document }
      else
      #puts "===DocumentsController.create:ko:"+@document.inspect
        flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_document), :msg => nil)
        format.html { render :action => "new" }
        format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
      end
    end
    LOG.debug (fname) {"flash=#{flash.inspect}"}
  end

  # PUT /documents/1
  # PUT /documents/1.xml
  def update
    fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    @volumes  = Volume.find_all
    @types    = Typesobject.get_types("document")
    @status   = Statusobject.get_status("document")
    LOG.debug (fname){"document.type=#{@document.typesobject}, commit=#{params["commit"] }"}
    if params["commit"] == t("update_type")
      LOG.debug (fname){"commit update_type"}
      ctrl_update_type @document, params[:document]
    else
      if commit_promote?
        ctrl_promote(@document)
      else
        @document.update_accessor(current_user)
        respond_to do |format|
          if @document.update_attributes(params[:document])
            flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_document), :ident => @document.ident)
            show_
            format.html { render :action => "show" }
            format.xml  { head :ok }
          else
            flash[:error] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_document), :ident => @document.ident)
            format.html { render :action => "edit" }
            format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
          end
        end
      end
    end
  end

  # PUT /documents/1
  # PUT /documents/1.xml
  def update_lifecycle
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    if commit_promote?
      ctrl_promote(@document)
    end
    if commit_demote?
      ctrl_demote(@document)
    end
    if commit_revise?
      ctrl_revise(@document)
    end
  end

  #
  # update of edit panel after changing the type
  #
  def update_type
    fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    ctrl_update_type @document, params[:object_type]
  end

  def new_forum
    @object = Document.find(params[:id])
    @types = Typesobject.get_types("forum")
    @status = Statusobject.get_status("forum")
    @relation_id = params["relation"]["forum"]
    respond_to do |format|
      flash[:notice] = ""
      @forum = Forum.new(user: current_user)
      @forum.subject = t(:ctrl_subject_forum, :typeobj => t(:ctrl_document), :ident => @object.ident)
      format.html { render :action => :new_forum, :id => @object.id }
      format.xml  { head :ok }
    end
  end

  def add_forum
    #LOG.info ("#{self.class.name}.#{__method__}") { "params=#{params.inspect}" }
    @document = Document.find(params[:id])
    ctrl_add_forum(@document)
  end

  # DELETE /documents/1
  # DELETE /documents/1.xml
  def destroy
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document= Document.find(params[:id])
    respond_to do |format|
      unless @document.nil?
        if @document.destroy
          flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_document), :ident => @document.ident)
          format.html { redirect_to(documents_url) }
          format.xml  { head :ok }
        else
          flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_document), :ident => @document.ident)
          index_
          format.html { render :action => "index" }
          format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
        end
      else
        flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_document), :ident => @document.ident)
      end
    end
  end

  #replaced by update_lifecycle
  def demote_obsolete
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    @volumes  = Volume.find_all
    @types    = Typesobject.get_types("document")
    @status   = Statusobject.get_status("document")
    ctrl_demote(@document)
  end

  def revise
    ctrl_revise(Document)
  end

  def check_out
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    chk = @document.check_out(params[:check],@current_user)
    unless chk.nil?
      flash[:notice] = t(:ctrl_object_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident, :reason => params[:check][:out_reason])
    else
      flash[:error] = t(:ctrl_object_not_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident)
    end
    respond_to do |format|
      format.xml  { head :ok }
      format.html { redirect_to(@document) }
    end
  end

  def check_in
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    chk = @document.check_in(params[:check], current_user)
    respond_to do |format|
      unless chk.nil?
        @document.update_accessor(current_user)
        @document.update_attributes(params[:document])
        flash[:notice] = t(:ctrl_object_checkin, :typeobj => t(:ctrl_document), :ident => @document.ident, :reason => params[:check][:in_reason])
      else
        flash[:error] = t(:ctrl_object_not_checkin, :typeobj => t(:ctrl_document), :ident => @document.ident)
      end
      format.xml  { head :ok }
      format.html { redirect_to(@document) }
    end
  end

  def check_free
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    chk = @document.check_free(params[:check], current_user)
    respond_to do |format|
      unless chk.nil?
        flash[:notice] = t(:ctrl_object_checkfree, :typeobj => t(:ctrl_document), :ident => @document.ident, :reason => params[:check][:in_reason])
      else
        flash[:error] = t(:ctrl_object_not_checkfree, :typeobj => t(:ctrl_document), :ident => @document.ident)
      end
      format.xml  { head :ok }
      format.html { redirect_to(@document) }
    end
  end

  #
  # preparation du datafile a associer
  #
  def new_datafile
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    @datafile = Datafile.new({:user => current_user, :thedocument => @document})
    ctrl_new_datafile(@document)
  end

  #
  # creation du datafile et association et liberation si besoin
  #
  def add_datafile
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    #LOG.debug (fname){"document=#{@document.inspect}"}
    ctrl_add_datafile(@document)
    LOG.debug (fname){"datafile=#{@datafile.inspect}"}
  end

  def add_docs
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    ctrl_add_objects_from_favorites(@document, :document)
  end

  def show_design
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    #LOG.debug (fname){"myparams=#{@myparams.inspect}"}
    document = Document.find(params[:id])
    ctrl_show_design(document, params[:type_model_id])
  end
  private

  def show_
    fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect} flash=#{flash.inspect}"}
    define_view
    @document  = Document.find(params[:id])
    #@relations = Relation.relations_for(@document)
    @tree         						= build_tree(@document, @myparams[:view_id])
    @tree_up      						= build_tree_up(@document, @myparams[:view_id] )
    @object_plm = @document
    LOG.debug (fname){"taille tree=#{@tree.size} flash=#{flash.inspect}"}
  end

  def index_
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @documents = Document.find_paginate({ :user=> current_user, :filter_types => params[:filter_types], :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
  end

end

