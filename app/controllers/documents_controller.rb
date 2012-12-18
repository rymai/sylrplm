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
			format.html { redirect_to(@document) }
		end
	end

	def show_
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
		define_view
		#puts __FILE__+"."+__method__.to_s+":"+params.inspect
		@document  = Document.find(params[:id])
		#@datafiles = @document.get_datafiles
		#@parts     = @document.parts
		#@projects  = @document.projects
		#@customers = @document.customers
		@checkout  = Check.get_checkout(@document)
		@tree      = build_tree(@document, @view_id)
		@tree_up   = build_tree_up(@document, @view_id)
		@relations = Relation.relations_for(@document)
		@tree         = build_tree(@document, @view_id, nil)
    @tree_up      = build_tree_up(@document, @view_id)
    LOG.debug (fname){"taille tree=#{@tree.size}"}
	end

	# GET /documents/new
	# GET /documents/new.xml
	def new
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
		@document = Document.new(user: current_user)
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
    LOG.debug (fname){"params=#{params.inspect}"}
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
    LOG.debug (fname){"params=#{params.inspect}"}
		#contournement pour faire le upload apres la creation pour avoir la revision dans
		#repository !!!!!!!!!!!!!!
		@document = Document.new(params[:document].merge(user: @current_user))
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
				flash[:notice] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_document), :msg => nil)
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
		@status   = Statusobject.find_for(@document)
		@document.update_accessor(current_user)
		respond_to do |format|
			if @document.update_attributes(params[:document])
				flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_document), :ident => @document.ident)
				format.html { redirect_to(@document) }
				format.xml  { head :ok }
			else
				flash[:notice] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_document), :ident => @document.ident)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /documents/1
	# DELETE /documents/1.xml
	def destroy
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
    @document= Document.find(params[:id])
		respond_to do |format|
			unless @document.nil?
				if @document.destroy
					flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_document), :ident => @document.ident)
					format.html { redirect_to(documents_url) }
					format.xml  { head :ok }
				else
					flash[:notice] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_document), :ident => @document.ident)
					index_
					format.html { render :action => "index" }
					format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
				end
			else
				flash[:notice] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_document), :ident => @document.ident)
			end
		end
	end

	def promote
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
		@volumes  = Volume.find_all
		@types    = Typesobject.find_for("document")
		@status   = Statusobject.find_for("document")
		ctrl_promote(@document)
	end

	def demote
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
		@volumes  = Volume.find_all
		@types    = Typesobject.find_for("document")
		@status   = Statusobject.find_for("document")
		ctrl_demote(@document)
	end

	def revise
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
		document     = Document.find(params[:id])
		previous_rev = document.revision
		@document    = document.revise
		@types       = Document.get_types_document
		@status      = Statusobject.find_for("document")
		respond_to do |format|
			unless @document.nil?
				if @document.save
					puts "documents_controller.revision apres save=#{@document.id}:#{@document.revision}"
					flash[:notice] = t(:ctrl_object_revised, :typeobj => t(:ctrl_document), :ident => @document.ident, :previous_rev => previous_rev, :revision => @document.revision)
					format.html { redirect_to(@document) }
					format.xml  { head :ok }
				else
					format.html { render :action => "edit" }
					format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
				end
			else
				@document = Document.find(params[:id])
				flash[:notice] = t(:ctrl_object_not_revised, :typeobj => t(:ctrl_document), :ident => @document.ident, :previous_rev => previous_rev)
				format.html { redirect_to(@document) }
				format.xml  { head :ok }
			end
		end
	end

	def check_out
    fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
		st=@document.check_out(params[:check],@current_user)
		if st != "already_checkout"
			if st != "no_reason"
				if st == "ok"
					flash[:notice] = t(:ctrl_object_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident, :reason => params[:out_reason])
				else
					flash[:notice] = t(:ctrl_object_notcheckout, :typeobj => t(:ctrl_document), :ident => @document.ident)
				end
			else
				flash[:notice] = t(:ctrl_object_give_reason)
			end
		else
			flash[:notice] = t(:ctrl_object_already_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident)
		end
		respond_to do |format|
			format.xml  { head :ok }
			format.html { redirect_to(@document) }
		end
	end

	def check_in
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
		st = @document.check_in(params[:check], current_user)
		respond_to do |format|
			if st != "no_reason"
				if st != "notyet_checkout"
					if st == "ok"
						update_accessor(@document)
						@document.update_attributes(params[:document])
						flash[:notice] = t(:ctrl_object_checkin, :typeobj => t(:ctrl_document), :ident => @document.ident, :reason => params[:in_reason])
					else
						flash[:notice] = t(:ctrl_object_not_checkin, :typeobj => t(:ctrl_document), :ident => @document.ident)
					end
				else
					flash[:notice] = t(:ctrl_object_notyet_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident)
				end
			else
				flash[:notice] = t(:ctrl_object_give_reason)
			end
			format.xml  { head :ok }
			format.html { redirect_to(@document) }
		end
	end

	def check_free
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
    @document = Document.find(params[:id])
		st = @document.check_free(params[:check], current_user)

		respond_to do |format|
			if st != "no_reason"
				if st != "notyet_checkout"
					if st == "ok"
						flash[:notice] = t(:ctrl_object_checkfree, :typeobj => t(:ctrl_document), :ident => @document.ident, :reason => params[:in_reason])
					else
						flash[:notice] = t(:ctrl_object_not_checkfree, :typeobj => t(:ctrl_document), :ident => @document.ident)
					end
				else
					flash[:notice] = t(:ctrl_object_give_reason)
				end
			else
				flash[:notice] = t(:ctrl_object_notyet_checkout, :typeobj => t(:ctrl_document), :ident => @document.ident)
			end
			format.xml  { head :ok }
			format.html { redirect_to(@document) }
		end
	end

	def new_datafile
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
    @object = Document.find(params[:id])
		@types  = Typesobject.find_for("datafile")
		respond_to do |format|
			if check = Check.get_checkout(@object)
				flash[:notice] = t(:ctrl_object_already_checkout, :typeobj => t(:ctrl_document), :ident => @object.ident, :reason => check.out_reason)
			else
				check = Check.new(object_to_check: @object, user: current_user, out_reason: t("ctrl_checkout_auto"))
				if check.save
				  LOG.debug (fname){"check saved=#{check.inspect}"}
					flash[:notice] = t(:ctrl_object_checkout, :typeobj => t(:ctrl_document), :ident => @object.ident, :reason => check.out_reason)
				else
					flash[:notice] = t(:ctrl_object_notcheckout, :typeobj => t(:ctrl_document), :ident => @object.ident)
					check = nil
				end
			end

			unless check.nil?
				@datafile = Datafile.new(user: current_user)
				format.html { render :action => :new_datafile, :id => @object.id }
				format.xml  { head :ok }
			end
		end
	end

	def add_docs
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
		@document = Document.find(params[:id])
		ctrl_add_objects_from_favorites(@document, :document)
	end

	def add_datafile
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
    @object = Document.find(params[:id])
		st=@object.add_datafile(params[:datafile], @current_user)
		respond_to do |format|
			flash[:notice] = ""
			if st!="ok"
				flash[:notice] += t(:ctrl_object_not_saved,:typeobj =>t(:ctrl_datafile),:ident=>nil,:msg=>nil)
				puts "document_controller.add_datafile:id=#{@object.id}"
				@types = Typesobject.find_for("datafile")
				@datafile = Datafile.new(user: current_user)
				format.html { render  :action => :new_datafile, :id => @object.id   }
			else
				format.html { redirect_to(@object) }
			end
			format.xml  { head :ok }
		end
	end

	def empty_favori
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
		empty_favori_by_type(get_model_type(params))
	end
	private

	def index_
		fname= "#{self.class.name}.#{__method__}"
    LOG.debug (fname){"params=#{params.inspect}"}
    @documents = Document.find_paginate({ :user=> current_user, :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
	end

end
