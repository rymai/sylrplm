class LinksController < ApplicationController
	include Controllers::PlmObjectControllerModule
	access_control(Access.find_for_controller(controller_class_name))
	before_filter :check_user, :only => [:new, :edit]
	# GET /links
	# GET /links.xml
	def index
		@links = Link.find_paginate({ :user=> current_user,:page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @links }
		end
	end

	def reset
		Link.reset
		respond_to do |format|
			format.html { redirect_to(links_url) }
			format.xml  { render :xml => @links }
		end
	end

	# GET /links/1
	# GET /links/1.xml
	def show
		@link = Link.find(params[:id])
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @link }
		end
	end

	# GET /links/new
	# GET /links/new.xml
	def new
		@link = Link.new
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @link }
		end
	end

	# GET /links/1/edit
	def edit
		@link = Link.find(params[:id])
	end

	# GET /links/1/edit_in_tree
	def edit_in_tree
		fname= "#{self.class.name}.#{__method__}"
		LOG.info (fname){"params=#{params.inspect}"}
		@link = Link.find(params[:id])
		@object_in_explorer=PlmServices.get_object(params[:object_model], params[:object_id])
	end

	# POST /links
	# POST /links.xml
	def create
		@link = Link.new(params[:link])
		respond_to do |format|
		#@link.values=params[:link][:values].to_json unless params[:link][:values].nil?
			if @link.save
				flash[:notice] = 'Link was successfully created.'
				format.html { redirect_to(@link) }
				format.xml  { render :xml => @link, :status => :created, :location => @link }
			else
				format.html { render :action => "new" }
				format.xml  { render :xml => @link.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /links/1
	# PUT /links/1.xml
	def update
		fname="#{self.class.name}.#{__method__}"
		LOG.info(fname){"params=#{params}"}
		@link = Link.find(params[:id])
		@link.update_accessor(current_user)
		respond_to do |format|
			values = OpenWFE::Json::from_json(params[:link][:values])
			LOG.info(fname){"values=#{values}"}
			if @link.update_attributes(params[:link])
				flash[:notice] = 'Link was successfully updated.'
				format.html { redirect_to(@link) }
				format.xml  { head :ok }
			else
				format.html { render :action => "edit" }
				format.xml  { render :xml => @link.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /links/1
	# DELETE /links/1.xml
	def destroy
		fname="#{self.class.name}.#{__method__}"
		LOG.info(fname){"params=#{params}"}
		@link = Link.find(params[:id])
		@link.destroy
		respond_to do |format|
			format.html { redirect_to(links_url) }
			format.xml  { head :ok }
		end
	end

	# DELETE /links/1
	# DELETE /links/1.xml
	def remove_link
		fname="#{self.class.name}.#{__method__}"
		LOG.info(fname){"params=#{params}"}
		@link = Link.find(params[:id])
		@link.destroy
		respond_to do |format|
			redir = unless session[:tree_object].nil?
				session[:tree_object]
			else
				links_url
			end
			format.html { redirect_to(redir) }
			format.xml  { head :ok }
		end
	end

	def empty_favori
		puts "#{self.class.name}.#{__method__}:#{params.inspect}"
		empty_favori_by_type(get_model_type(params))
	end

end