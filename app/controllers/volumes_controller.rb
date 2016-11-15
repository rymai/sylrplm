class VolumesController < ApplicationController
	include Controllers::PlmObjectControllerModule
	access_control (Access.find_for_controller(controller_name.classify))
	# GET /volumes
	# GET /volumes.xml
	def index
		index_
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @volumes }
		end
	end

	def index_
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"current_user=#{current_user} params=#{params} "}
		@volumes = Volume.find_paginate({:user=> current_user, :filter_types => params[:filter_types],:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
		@object_plms=@volumes
	end

	def index_execute
		ctrl_index_execute
	end

	# GET /volumes/1
	# GET /volumes/1.xml
	def show
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @volume }
		end
	end

	# GET /volumes/new
	# GET /volumes/new.xml
	def new
		@volume = Volume.new
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @volume }
		end
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		@object_orig = Volume.find(params[:id])
		@object = @object_orig.duplicate(current_user)
		@volume=@object
		LOG.debug(fname) {"object=#{@object}"}
		respond_to do |format|
			format.html
			format.xml  { render :xml => @object }
		end
	end

	# GET /volumes/1/edit
	def edit
		@volume = Volume.find(params[:id])
	end

	# POST /volumes
	# POST /volumes.xml
	def create
		#puts "volumes_controller.create:"+params.inspect
		@volume = Volume.new(params[:volume])
		#puts "volumes_controller.create:errors="+@volume.errors.count.to_s+":"+@volume.errors.inspect
		respond_to do |format|
			if fonct_new_dup?
				object_orig=Volume.find(params[:object_orig_id])
			st = @volume.create_duplicate(object_orig)
			else
			st = @volume.save
			end
			if st
				flash[:notice] = t(:ctrl_object_created,:typeobj => t(:ctrl_volume), :ident=>@volume.name)
				params[:id]= @volume.id
				show_
				format.html { render :action => "show" }
				format.xml  { render :xml => @volume, :status => :created, :location => @volume }
			else
				flash[:error] = t(:ctrl_object_not_created,:typeobj => t(:ctrl_volume), :ident=>@volume.name, :msg => nil)
				format.html { render :controller => :volume, :action => "new" }
				format.xml  { render :xml => the_errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /volumes/1
	# PUT /volumes/1.xml
	def update
		fname="#{self.class.name}.#{__method__}"+":"
		#LOG.info(fname){"id=#{params[:id]}"}
		@volume = Volume.find(params[:id])
		@volume.update_accessor(current_user)
		#LOG.info(fname){"volume=#{@volume}"}
		respond_to do |format|
			if @volume.update_attributes(params[:volume])
				LOG.info(fname){"volume=#{@volume}"}
				flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_volume),:ident=>@volume.name)
				show_
				format.html { render :action => "show" }
				format.xml  { head :ok }
			else
				LOG.info(fname){"volume=#{@volume}"}
				flash[:error] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_volume),:ident=>@volume.name, :error => @volume.errors.full_messages)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @volume.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /volumes/1
	# DELETE /volumes/1.xml
	def destroy
		@volume = Volume.find(params[:id])
		name=@volume.name
		dir=@volume.directory
		st=@volume.destroy_volume
		respond_to do |format|
			if st
				flash[:notice] = t(:ctrl_object_deleted,:typeobj =>t(:ctrl_volume), :ident=>"#{name}:#{dir}")
				format.html { redirect_to(volumes_url) }
				format.xml  { head :ok }
			else
				flash[:error] = t(:ctrl_object_not_deleted,:typeobj =>t(:ctrl_volume), :ident=>"#{name}:#{dir}")
				puts "volumes_controller.destroy:errors="+@volume.errors.inspect
				format.html { render :action => "show" }
				format.xml  { head :ok }
			end
		end
	end

	private

	def show_
		@volume = Volume.find(params[:id])
	end
end
