class DocumentsController < ApplicationController
	include Controllers::PlmObjectControllerModule
	#droits d'acces suivant le controller et l'action demandee
	#administration par le menu Access
	#access_control (Document.controller_access())
	access_control(Access.find_for_controller(controller_name.classify))
	respond_to :html, :js
	# GET /documents
	# GET /documents.xml
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

	# GET /documents/1
	# GET /documents/1.xml
	def show_old
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @object_plm }
		end
	end

	def select_view
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

	# GET /documents/new
	# GET /documents/new.xml
	def new
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"params=#{params.inspect}"}
		params={}
		@object_plm = Document.new(:user => current_user)
		LOG.debug(fname) {"new:@object_plm=#{@object_plm.inspect}"}
		@types    = Typesobject.get_types("document")
		@volumes  = Volume.all.to_a
		@status   = Statusobject.get_status("document", 2)
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @object_plm }
		end
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_orig = Document.find(params[:id])
		@object_plm = @object = @object_orig.duplicate(current_user)
		@types    = Typesobject.get_types("document")
		@status   = Statusobject.get_status("document", 2)
		respond_to do |format|
			format.html # document/1/new_dup
			format.xml  { render :xml => @object_plm }
		end
	end

	# GET /documents/1/edit
	def edit
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"params=#{params.inspect}"}
		@object_plm = Document.find_edit(params[:id])
		@types    = Typesobject.get_types("document")
	end

	# GET /documents/1/edit_lifecycle
	def edit_lifecycle
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname) {"params=#{params.inspect}"}
		@object_plm = Document.find_edit(params[:id])
	end

	# POST /documents
	# POST /documents.xml
	def create
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"create:params=#{params.inspect}"}
		#contournement pour faire le upload apres la creation pour avoir la revision dans
		#repository !!!!!!!!!!!!!!
		#docpar=document_params
		#LOG.debug(fname) {"create:document_params=#{docpar}"}

		@object_plm = Document.new(params[:document])
		@object_plm.def_user(current_user)
		#rails4 @object_plm = Document.new(docpar)
		LOG.debug(fname) {"create:@object_plm=#{@object_plm.inspect}"}
		@types    = Typesobject.get_types("document")
		@status   = Statusobject.get_status("document")
		respond_to do |format|
			if fonct_new_dup?
				object_orig=Document.find(params[:object_orig_id])
			st = @object_plm.create_duplicate(object_orig)
			else
			st = @object_plm.save
			end
			if st
				st = ctrl_duplicate_links(params, @object_plm, current_user)
				flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_document), :ident => @object_plm.ident)
				###format.html { redirect_to(@object_plm) }
				# tout ceci pour ne pas perdre le flash
				params[:id]=@object_plm.id
				show_
				format.html { render :action => "show"}
				format.xml  { render :xml => @object_plm, :status => :created, :location => @object_plm }
			else
				flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_document), :msg => nil)
				LOG.debug(fname) {"errors=#{@object_plm.errors.full_messages}"}
				format.html { render :action => "new" }
				format.xml  { render :xml => @object_plm.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /documents/1
	# PUT /documents/1.xml
	def update
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Document.find(params[:id])
		@volumes  = Volume.all.to_a
		@types    = Typesobject.get_types("document")
		@status   = Statusobject.get_status("document")
		LOG.debug(fname){"document.type=#{@object_plm.typesobject}, commit=#{params["commit"] }"}
		if params["commit"] == t("update_type")
			LOG.debug(fname){"commit update_type"}
			ctrl_update_type @object_plm, params[:document]
		else
			if commit_promote?
				ctrl_promote(@object_plm)
			else
				@object_plm.update_accessor(current_user)
				respond_to do |format|
					if @object_plm.update_attributes(params[:document])
						flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_document), :ident => @object_plm.ident)
						show_
						format.html { render :action => "show" }
						format.xml  { head :ok }
					else
						flash[:error] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_document), :ident => @object_plm.ident, :error => @object_plm.errors.full_messages)
						format.html { render :action => "edit" }
						format.xml  { render :xml => @object_plm.errors, :status => :unprocessable_entity }
					end
				end
			end
		end
	end

	# PUT /documents/1
	# PUT /documents/1.xml
	def update_lifecycle
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Document.find(params[:id])
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
		@object_plm = Document.find(params[:id])
		ctrl_update_type @object_plm, params[:object_type]
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
		@object_plm = Document.find(params[:id])
		ctrl_add_forum(@object_plm)
	end

	# DELETE /documents/1
	# DELETE /documents/1.xml
	def destroy_old
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm= Document.find(params[:id])
		respond_to do |format|
			unless @object_plm.nil?
				if @object_plm.destroy
					flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_document), :ident => @object_plm.ident)
					format.html { redirect_to(documents_url) }
					format.xml  { head :ok }
				else
					flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_document), :ident => @object_plm.ident)
					index_
					format.html { render :action => "index" }
					format.xml  { render :xml => @object_plm.errors, :status => :unprocessable_entity }
				end
			else
				flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_document), :ident => @object_plm.ident)
			end
		end
	end

	def revise
		ctrl_revise(Document)
	end

	def check_out
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Document.find(params[:id])
		chk = @object_plm.check_out(params[:check],@current_user)
		LOG.debug(fname){"params[:check]=#{params[:check]} check_out=#{chk}"}
		unless chk.nil?
			flash[:notice] = t(:ctrl_object_checkout, :typeobj => t(:ctrl_document), :ident => @object_plm.ident, :reason => params[:check][:out_reason])
		else
			flash[:error] = t(:ctrl_object_not_checkout, :typeobj => t(:ctrl_document), :ident => @object_plm.ident)
		end
		respond_to do |format|
			format.xml  { head :ok }
			format.html { redirect_to(@object_plm) }
		end
	end

	def check_in
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Document.find(params[:id])
		chk = @object_plm.check_in(params[:check], current_user)
		respond_to do |format|
			unless chk.nil?
				@object_plm.update_accessor(current_user)
				@object_plm.update_attributes(params[:document])
				flash[:notice] = t(:ctrl_object_checkin, :typeobj => t(:ctrl_document), :ident => @object_plm.ident, :reason => params[:check][:in_reason])
			else
				flash[:error] = t(:ctrl_object_not_checkin, :typeobj => t(:ctrl_document), :ident => @object_plm.ident)
			end
			format.xml  { head :ok }
			format.html { redirect_to(@object_plm) }
		end
	end

	def check_free
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Document.find(params[:id])
		chk = @object_plm.check_free(params[:check], current_user)
		respond_to do |format|
			unless chk.nil?
				flash[:notice] = t(:ctrl_object_checkfree, :typeobj => t(:ctrl_document), :ident => @object_plm.ident, :reason => params[:check][:in_reason])
			else
				flash[:error] = t(:ctrl_object_not_checkfree, :typeobj => t(:ctrl_document), :ident => @object_plm.ident)
			end
			format.xml  { headrameters into a new or create method the after_initializ :ok }
			format.html { redirect_to(@object_plm) }
		end
	end

	#
	# preparation du datafile a associer
	#
	def new_datafile
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Document.find(params[:id])
		@datafile = Datafile.new({:user => current_user, :thedocument => @object_plm})
		@datafile.document=@object_plm
		ctrl_new_datafile(@object_plm)
	end

	#
	# creation du datafile et association et liberation si besoin
	#
	def add_datafile
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Document.find(params[:id])
		LOG.debug(fname){"document=#{@object_plm.inspect}"}
		ctrl_add_datafile(@object_plm)
		LOG.debug(fname){"datafile=#{@datafile.inspect}"}
	end

	def add_docs
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Document.find(params[:id])
		ctrl_add_objects_from_clipboardtes(@object_plm, :document)
	end

	def show_design
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		#LOG.debug(fname){"myparams=#{@myparams.inspect}"}
		document = Document.find(params[:id])
		ctrl_show_design(document, params[:type_model_id])
	end

	private

	def show_
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect} flash=#{flash.inspect}"}
		define_view
		@object_plm  = Document.find(params[:id])
		LOG.debug(fname){"params[:id]=#{params[:id]} @object_plm=#{@object_plm}"}
		@tree         						= build_tree(@object_plm, @myparams[:view_id])
		@tree_up      						= build_tree_up(@object_plm, @myparams[:view_id] )
		@object_plm = @object_plm
		LOG.debug(fname){"taille tree=#{@tree.size} flash=#{flash.inspect}"}
	end

	def index_
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"index_params=#{params.inspect} object_plm=#{@object_plm}"}
		@object_plms = Document.find_paginate({ :user=> current_user, :filter_types => params[:filter_types], :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
	end

	def document_params
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"document_params debut=#{params.inspect}"}
		ret=nil
		ret=params.require(:document).permit(:id,:ident,  :revision, :typesobject_id, :statusobject_id, :designation, :description, :owner_id, :date)
		#ret=params.require(:document).permit()
		#params.require(:document).permit!
		LOG.debug(fname){"document_params fin=#{params.inspect}"}
		LOG.debug(fname){"ret fin=#{ret.inspect}"}
		ret
	end

end

