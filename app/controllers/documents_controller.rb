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

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"params=#{params.inspect}"}
		@object_orig = Document.find(params[:id])
		@document = @object = @object_orig.duplicate(current_user)
		@types    = Typesobject.get_types("document")
		@status   = Statusobject.find_for("document", 2)
		respond_to do |format|
			format.html # document/1/new_dup
			format.xml  { render :xml => @document }
		end
	end

	# GET /documents/1/edit
	def edit
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"params=#{params.inspect}"}
		@document = Document.find_edit(params[:id])
		@types    = Typesobject.find_for("document")
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
		@types    = Document.get_types_document
		@status   = Statusobject.find_for("document")
		respond_to do |format|
			if params[:fonct] == "new_dup"
				object_orig=Document.find(params[:object_orig_id])
			st = @document.create_duplicate(object_orig)
			else
			st = @document.save
			end
			if st
				st = ctrl_duplicate_links(params, @document, current_user)
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
		LOG.debug (fname){"params=#{params.inspect}"}
		@document = Document.find(params[:id])
		@volumes  = Volume.find_all
		@types    = Typesobject.find_for("document")
		@status   = Statusobject.find_for("document")
		if commit_promote?
			ctrl_promote(@document)
		else
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
	end

	# PUT /documents/1
	# PUT /documents/1.xml
	def update_lifecycle
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname){"params=#{params.inspect}"}
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

	def new_forum
		@object = Document.find(params[:id])
		@types = Typesobject.find_for("forum")
		@status = Statusobject.find_for("forum")
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

	def promote_by_menu_obsolete
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname){"params=#{params.inspect}"}
		promote_
	end

	def promote_by_action_obsolete
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname){"params=#{params.inspect}"}
		promote_
	end

	def promote__obsolete

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
		ctrl_revise(Document)
	end

	def revise_obsolete
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
		ctrl_show_design(document)
	end
	private

	def show_
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname){"params=#{params.inspect}"}
		define_view
		@document  = Document.find(params[:id])
		#@relations = Relation.relations_for(@document)
		@tree         						= build_tree(@document, @myparams[:view_id])
		@tree_up      						= build_tree_up(@document, @myparams[:view_id] )
		@object_plm = @document
		LOG.debug (fname){"taille tree=#{@tree.size}"}
	end

	def index_
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"params=#{params.inspect}"}
		@documents = Document.find_paginate({ :user=> current_user, :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
	end

end

