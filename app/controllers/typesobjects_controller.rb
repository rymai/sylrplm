class TypesobjectsController < ApplicationController
	include Controllers::PlmObjectController
	access_control (Access.find_for_controller(controller_name.classify))
	# GET /typesobjects
	# GET /typesobjects.xml
	def index
		ctrl_index
	end
	def index_old
		index_
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @typesobjects }
		end
	end

	def index_
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"filter_types=#{params[:filter_types]} query=#{params[:query]}"}
		@typesobjects = Typesobject.find_paginate({:user=> current_user, :filter_types => params[:filter_types],:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
@object_plms=@typesobjects
	end

	def index_execute
		ctrl_index_execute
	end

	# GET /typesobjects/1
	# GET /typesobjects/1.xml
	def show
		show_
		# objets pouvant etre types
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @typesobject }
		end
	end

	# GET /typesobjects/new
	# GET /typesobjects/new.xml
	def new
		@typesobject = Typesobject.new
		@objectswithtype=Typesobject.get_objects_with_type
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @typesobject }
		end
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		@object_orig = Typesobject.find(params[:id])
		@object = @object_orig.duplicate(current_user)
		@typesobject=@object
		@objectswithtype=Typesobject.get_objects_with_type
		respond_to do |format|
			format.html
			format.xml  { render :xml => @object }
		end
	end

	# GET /typesobjects/1/edit
	def edit
		fname="#{self.class.name}.#{__method__}"
		LOG.info(fname){">>>>params=#{params}"}
		@typesobject = Typesobject.find(params[:id])
		#pour tester le champ field et avoir une erreur
		fieldsvalues=@typesobject.get_fields_values
		@typesobject.fields="{}" if @typesobject.fields.nil?
		@objectswithtype=Typesobject.get_objects_with_type
		LOG.info(fname){"<<<<@typesobject=#{@typesobject} @objectswithtype=#{@objectswithtype} @typesobject.fields=#{@typesobject.fields} errors=#{@typesobject.errors.full_messages}"}
	end

	# POST /typesobjects
	# POST /typesobjects.xml
	def create
		fname="#{self.class.name}.#{__method__}"
		#LOG.info(fname){"params=#{params}"}
		@typesobject = Typesobject.new(params[:typesobject])
		@objectswithtype=Typesobject.get_objects_with_type
		respond_to do |format|
			if !params[:fonct].nil? && !params[:fonct][:current].nil? && params[:fonct][:current] == "new_dup"
				object_orig=Typesobject.find(params[:object_orig_id])
			st = @typesobject.create_duplicate(object_orig)
			else
			st = @typesobject.save
			end
			if st
				flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_typesobject),:ident=>@typesobject.ident)
				params[:id]= @typesobject.id
				show_
				format.html { render :action => "show" }
				format.xml  { render :xml => @typesobject, :status => :created, :location => @typesobject }
			else
				flash[:error] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_typesobject),:ident=>@typesobject.name, :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @typesobject.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /typesobjects/1
	# PUT /typesobjects/1.xml
	def update
		@typesobject = Typesobject.find(params[:id])
		@objectswithtype=Typesobject.get_objects_with_type
		@typesobject.update_accessor(current_user)
		respond_to do |format|
			if @typesobject.update_attributes(params[:typesobject])
				flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_typesobject),:ident=>@typesobject.name)
				show_
				format.html { render :action => "show" }
				format.xml  { head :ok }
			else
				flash[:error] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_typesobject),:ident=>@typesobject.name, :error => @typesobject.errors.full_messages)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @typesobject.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /typesobjects/1
	# DELETE /typesobjects/1.xml
	def destroy_old
		@typesobject = Typesobject.find(params[:id])
		if @typesobject.destroy
			flash[:notice] = t(:ctrl_object_deleted,:typeobj =>t(:ctrl_typesobject),:ident=>@typesobject.name)
		else
			flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_typesobject),:ident=>@typesobject.name)
		end
		respond_to do |format|
			format.html { redirect_to(typesobjects_url) }
			format.xml  { head :ok }
		end
	end

	#
	# update of edit panel after changing the forobject
	#
	def update_forobject
		fname= "#{self.class.name}.#{__method__}"
		object_forobject=params[:object_forobject]
		@typesobject = ::Typesobject.find(params[:id])
		@objectswithtype=Typesobject.get_objects_with_type
		LOG.debug(fname){"params=#{params.inspect}"}
		LOG.debug(fname){"object_forobject=#{object_forobject} @typesobject=#{@typesobject.inspect}"}
		ctrl_update_forobject(@typesobject, params[:object_forobject], )
	end

	private

	def show_
		@typesobject = Typesobject.find(params[:id])
	end
end
