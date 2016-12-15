class RelationsController < ApplicationController
	include Controllers::PlmObjectController
	layout "application"
	#access_control (Access.find_for_controller(controller_name.classify))
	# GET /relations
	# GET /relations.xml
	def index
		ctrl_index
	end

	def index_old
		index_
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @relations }
		end
	end

	def index_
		@relations = Relation.find_paginate({ :user=> current_user, :filter_types => params[:filter_types], :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
		@object_plms=@relations

	end

	def index_execute
		ctrl_index_execute
	end

	# GET /relations/1
	# GET /relations/1.xml
	def show
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @relation }
		end
	end

	# GET /relations/new
	# GET /relations/new.xml
	def new
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname) {"params=#{params}"}
		@relation = Relation.new
		@views = View.all
		@types  = Typesobject.get_types("relation")
		@status = Statusobject.get_status("relation")
		#LOG.debug(fname) {"relation=#{@relation.inspect}"}
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @relation }
		end
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		@object_orig = Relation.find(params[:id])
		@object = @object_orig.duplicate(current_user)
		@relation=@object
		@views = View.all
		@types  = Typesobject.get_types("relation")
		@status = Statusobject.get_status("relation")
		respond_to do |format|
			format.html
			format.xml  { render :xml => @object }
		end
	end

	# GET /relations/1/edit
	def edit
		fname= "#{self.class.name}.#{__method__}"
		@relation = Relation.find(params[:id])
		@views = View.all
		@types  = Typesobject.get_types("relation")
		@status = Statusobject.get_status("relation")
		LOG.debug(fname) {"typesobject=#{@relation.typesobject}"}
	end

	# POST /relations
	# POST /relations.xml
	def create
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"params=#{params.inspect}"}
		@relation = Relation.new(params[:relation])
		@views = View.all
		@types  = Typesobject.get_types("relation")
		@status = Statusobject.get_status("relation")
		respond_to do |format|
			LOG.debug(fname) {"relation=#{@relation.inspect}"}
			if params[:fonct][:current] == "new_dup"
				object_orig=Relation.find(params[:object_orig_id])
			st = @relation.create_duplicate(object_orig)
			else
			st = @relation.save
			end
			if st
				flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_relation),:ident=>@relation.ident)
				#format.html { redirect_to(@relation, :notice => 'Relation was successfully created.') }
				params[:id]=@relation.id
				show_
				format.html { render :action => "show" }
				format.xml  { render :xml => @relation, :status => :created, :location => @relation }
			else
				flash[:error] =t(:ctrl_object_not_created, :typeobj =>t(:ctrl_relation), :msg => @relation.ident)
				format.html { render :action => "new" }
				format.xml  { render :xml => @relation.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /relations/1
	# PUT /relations/1.xml
	def update
		@relation = Relation.find(params[:id])
		@views = View.all
		@types  = Typesobject.get_types("relation")
		@status = Statusobject.get_status("relation")
		@relation.update_accessor(current_user)
		respond_to do |format|
			if @relation.update_attributes(params[:relation])
				flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_relation),:ident=>@relation.ident)
				show_
				format.html { render :action => "show" }
				#format.html { redirect_to(@relation, :notice => 'Relation was successfully updated.') }
				format.xml  { head :ok }
			else
				flash[:error] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_relation),:ident=>@relation.ident, :error => @object_plm.errors.full_messages)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @relation.errors, :status => :unprocessable_entity }
			end
		end
	end

	#
	# update of edit panel after changing the type
	#
	def update_type
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@relation = Relation.find(params[:id])
		@types  = Typesobject.get_types("relation")
		@status = Statusobject.get_status("relation")
		ctrl_update_type @relation, params[:object_type]
	end

	# DELETE /relations/1
	# DELETE /relations/1.xml
	def destroy_old
		@relation = Relation.find(params[:id])
		if @relation.destroy
			flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_relation), :ident => @relation.ident)
		else
			flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_relation), :ident => @relation.ident)
		end
		respond_to do |format|
			format.html { redirect_to(relations_url) }
			format.xml  { head :ok }
		end
	end

	def update_father
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
	#inutilise @relation_datas = Relation.datas_by_params(params)
	end

	def update_child
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
	#inutilise @relation_datas = Relation.datas_by_params(params)
	end

	private

	def show_
		@relation = Relation.find(params[:id])
	end

end
