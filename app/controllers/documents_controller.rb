class DocumentsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  before_filter :check_init, :only => :new
  #droits d'acces suivant le controller et l'action demandee
  #administration par le menu Access
  #access_control (Document.controller_access())
  access_control(Access.find_for_controller(controller_class_name))
  before_filter :check_user, :only => [:new, :edit]
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
    show_
    respond_to do |format|
      format.html { render :action => "show" }
      format.xml  { render :xml => @document }
    end
  end
	
  # GET /documents/new
  # GET /documents/new.xml
  def new
    fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname) {"params=#{params.inspect}"}
    params={}
    @document = Document.new(:user => current_user)
    @types    = Document.get_types_document
    @volumes  = Volume.find_all
    @status   = Statusobject.find_for("document", 2)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @document }
    end
  end

  # GET /documents/1/edit
  def edit
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname) {"params=#{params.inspect}"}
    @document = Document.find_edit(params[:id])
    @types    = Typesobject.find_for("document")
    @volumes  = Volume.find_all
    #seulement les statuts qui peuvent etre promus ou retrograde par le menu
    @status   = Statusobject.find_for(@document, 1)
  end

  # POST /documents
  # POST /documents.xml
  def create
    fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname) {"params=#{params.inspect}"}
    #contournement pour faire le upload apres la creation pour avoir la revision dans
    #repository !!!!!!!!!!!!!!
    @document = Document.new(params[:document])
    @types    = Document.get_types_document
    @status   = Statusobject.find_for("document")
    #@volumes  = Volume.find_all
    respond_to do |format|
    #puts "===DocumentsController.create:"+@document.inspect
      if @document.save
        #puts "===DocumentsController.create:ok:"+@document.inspect
        flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_document), :ident => @document.ident)
        format.html { redirect_to(@document) }
        format.xml  { render :xml => @document, :status => :created, :location => @document }
      else
      #puts "===DocumentsController.create:ko:"+@document.inspect
        flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_document), :msg => nil)
        format.html { render :action => "new" }
        format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /documents/1
  # PUT /documents/1.xml
  def update
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    @volumes  = Volume.find_all
    @types    = Typesobject.find_for("document")
    @status   = Statusobject.find_for(@document)
    @document.update_accessor(current_user)
    respond_to do |format|
      if @document.update_attributes(params[:document])
        flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_document), :ident => @document.ident)
        format.html { redirect_to(@document) }
        format.xml  { head :ok }
      else
        flash[:error] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_document), :ident => @document.ident)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
      end
    end
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

  def promote
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    @volumes  = Volume.find_all
    @types    = Typesobject.find_for("document")
    @status   = Statusobject.find_for("document")
    ctrl_promote(@document)
  end

  def demote
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    @volumes  = Volume.find_all
    @types    = Typesobject.find_for("document")
    @status   = Statusobject.find_for("document")
    ctrl_demote(@document)
  end

  def revise
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    document     = Document.find(params[:id])
    previous_rev = document.revision
    @document    = document.revise
    @types       = Document.get_types_document
    @status      = Statusobject.find_for("document")
    respond_to do |format|
      unless @document.nil?
        if @document.save
          #puts "documents_controller.revision apres save=#{@document.id}:#{@document.revision}"
          flash[:notice] = t(:ctrl_object_revised, :typeobj => t(:ctrl_document), :ident => @document.ident, :previous_rev => previous_rev, :revision => @document.revision)
          format.html { redirect_to(@document) }
          format.xml  { head :ok }
        else
        	flash[:error] = t(:ctrl_object_not_revised, :typeobj => t(:ctrl_document), :ident => @document.ident, :previous_rev => previous_rev)
          format.html { render :action => "edit" }
          format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
        end
      else
        @document = Document.find(params[:id])
        flash[:error] = t(:ctrl_object_not_revised, :typeobj => t(:ctrl_document), :ident => @document.ident, :previous_rev => previous_rev)
        format.html { redirect_to(@document) }
        format.xml  { head :ok }
      end
    end
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
        update_accessor(@document)
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
	
	def new_datafile_old
		fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
		@types  = Typesobject.find_for("datafile")	
		check = Check.get_checkout(@document)
		unless check.nil?
			flash[:notice] = t(:ctrl_object_already_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident, :reason => check.out_reason)
		else
			if current_user.check_automatic			
				check = Check.new(object_to_check: @document, user: current_user, out_reason: t(:ctrl_checkout_auto))
				if check.save
				  #LOG.debug (fname){"check saved=#{check.inspect}"}
					flash[:notice] = t(:ctrl_object_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident, :reason => check.out_reason)
				else
					#LOG.debug (fname){"check errors=#{check.errors.inspect}"}
					flash[:error] = t(:ctrl_object_not_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident)
					check = nil
				end
			else
				check = nil
				flash[:error] = t(:ctrl_object_not_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident)
			end
		end
		respond_to do |format|
			@datafile = Datafile.new(user: current_user)
			unless check.nil?	
				#LOG.debug (fname){"document=#{@document.inspect}"}
				@datafile.document = @document
				flash[:notice] = t(:ctrl_object_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident, :reason => check.out_reason)
				format.html { render :action => :new_datafile, :id => @document.id }
				format.xml  { head :ok }
			else
				flash[:error] = t(:ctrl_object_not_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident)
				format.html { redirect_to(@document) }
				format.xml  { head :ok }
			end
		end
	end
	
	def add_datafile_old
		fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
    #LOG.debug (fname){"document=#{@document.inspect}"}
		@datafile = @document.datafiles.build(params[:datafile])
		#LOG.debug (fname){"datafile=#{@datafile.inspect}"}
			respond_to do |format|				
				if @document.save
					if current_user.check_automatic	
						check = Check.get_checkout(@document)
						unless check.nil?
							check = check.checkIn({:in_reason => t("ctrl_checkin_auto")}, current_user)	
							#LOG.debug (fname){"check errors==#{check.errors.inspect}"}
							if check.save
					  		#LOG.debug (fname){"check saved=#{check.inspect}"}
								flash[:notice] = t(:ctrl_object_checkin, :typeobj => t(:ctrl_document), :ident => @document.ident, :reason => check.in_reason)
							else
								flash[:error] = t(:ctrl_object_not_checkin, :typeobj => t(:ctrl_document), :ident => @document.ident)
								check = nil
							end
						else
							flash[:error] = t(:ctrl_object_not_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident)
						end
					end
					format.html { redirect_to(@document) }
				else
					flash[:error] = t(:ctrl_object_not_saved,:typeobj =>t(:ctrl_datafile),:ident=>nil,:msg=>nil)
					@types = Typesobject.find_for("datafile")
					format.html { render :action => :new_datafile, :id => @document.id   }
				end
			end
			
	end

	def add_docs
		fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
		@document = Document.find(params[:id])
		ctrl_add_objects_from_favorites(@document, :document)
	end

	def empty_favori
		fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    empty_favori_by_type(get_model_type(params))
  end

private
	
	def show_
		fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
		define_view
		@document  = Document.find(params[:id])
		@relations = Relation.relations_for(@document)
    @tree         						= build_tree(@document, @myparams[:view_id])
		@tree_up      						= build_tree_up(@document, @myparams[:view_id] )
    #LOG.debug (fname){"taille tree=#{@tree.size}"}
	end
	
  def index_
    fname= "#{self.class.name}.#{__method__}"
    #LOG.debug (fname){"params=#{params.inspect}"}
    @documents = Document.find_paginate({ :user=> current_user, :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
  end
  
  end
  

