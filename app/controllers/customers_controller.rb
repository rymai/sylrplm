class CustomersController < ApplicationController
	include Controllers::PlmObjectControllerModule
	access_control(Access.find_for_controller(controller_name.classify))

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

# GET /customers
	# GET /customers.xml
	def index
		ctrl_index
	end

	def index_execute
		ctrl_index_execute
	end

	# GET /customers/1
	# GET /customers/1.xml
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
			#  object with his tree if ask
		show_
		# objects
		index_
			respond_to do |format|
				format.html { render :action => "show" }
				format.xml  { render :xml => @object_plm }
			end
		end
	end

	def show_
		unless params[:id].nil?
			@object_plm                = Customer.find(params[:id])
			@tree         						= build_tree(@object_plm, @myparams[:view_id], nil, 3)
			@tree_up      						= build_tree_up(@object_plm, @myparams[:view_id] )
		end
	end

	# GET /customers/new
	# GET /customers/new.xml
	def new
		#puts "===CustomersController.new:"+params.inspect+" user="+@current_user.inspect
		@object_plm = Customer.new(user: current_user)
		@types    = Typesobject.get_types("customer")
		@status   = Statusobject.get_status("customer", 2)
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @object_plm }
		end
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@object_orig = Customer.find(params[:id])
		@object = @object_orig.duplicate(current_user)
		@object_plm=@object
		LOG.debug(fname){"new customer=#{@object_plm.inspect}"}
		@types    = Typesobject.get_types("customer")
		@status   = Statusobject.get_status("customer", 2)
		respond_to do |format|
			format.html # customer/1/new_dup
			format.xml  { render :xml => @object_plm }
		end
	end

	# GET /customers/1/edit
	def edit
		@object_plm = Customer.find_edit(params[:id])
		@types    = Typesobject.get_types("customer")
	end

	# GET /customers/1/edit_lifecycle
	def edit_lifecycle
		@object_plm = Customer.find_edit(params[:id])
	end

	# POST /customers
	# POST /customers.xml
	def create
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname) {"params=#{params.inspect}"}
		@object_plm = Customer.new(params[:customer])
		@object_plm.def_user(current_user)
		@types    = Typesobject.get_types("customer")
		@status   = Statusobject.get_status(@object_plm)
		respond_to do |format|
			if fonct_new_dup?
				object_orig=Customer.find(params[:object_orig_id])
			st = @object_plm.create_duplicate(object_orig)
			else
			st = @object_plm.save
			end
			if st
				st = ctrl_duplicate_links(params, @object_plm, current_user)
				flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_customer), :ident => @object_plm.ident)
				params[:id]=@object_plm.id
				show_
				format.html { render :action => "show" }
				format.xml  { render :xml => @object_plm, :status => :created, :location => @object_plm }
			else
				flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_customer), :msg => @object_plm.errors)
				format.html { render :action => :new }
				format.xml  { render :xml => @object_plm.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /customers/1
	# PUT /customers/1.xml
	def update
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname) {"params=#{params.inspect}"}
		@object_plm = Customer.find(params[:id])
		@types    = Typesobject.get_types(:customer)
		@status   = Statusobject.get_status(@object_plm)
		@object_plm.update_accessor(current_user)
		if commit_promote?
			ctrl_promote(@object_plm)
		else
			respond_to do |format|
				if @object_plm.update_attributes(params[:customer])
					flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_customer), :ident => @object_plm.ident)
					show_
					format.html { render :action => "show" }
					format.xml  { head :ok }
				else
					flash[:error] = t(:ctrl_object_notupdated, :typeobj => t(:ctrl_customer), :ident => @object_plm.ident)
					format.html { render :action => :edit }
					format.xml  { render :xml => @object_plm.errors, :status => :unprocessable_entity }
				end
			end
		end
	end

	def update_lifecycle
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Customer.find(params[:id])
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
		@object_plm = Customer.find(params[:id])
		ctrl_update_type @object_plm, params[:object_type]
	end

	# DELETE /customers/1
	# DELETE /customers/1.xml
	def destroy_old
		@object_plm = Customer.find(params[:id])
		respond_to do |format|
			unless @object_plm.nil?
				if @object_plm.destroy
					flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_customer), :ident => @object_plm.ident)
					format.html { redirect_to(customers_url) }
					format.xml  { head :ok }
				else
					flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_customer), :ident => @object_plm.ident)
					index_
					format.html { render :action => "index" }
					format.xml  { render :xml => @object_plm.errors, :status => :unprocessable_entity }
				end
			else
				flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_customer), :ident => @object_plm.ident)
			end
		end
	end

	def promote_by_menu
		promote_
	end

	def promote_by_action
		promote_
	end

	def promote_
		ctrl_promote(Customer,false)
	end

	def demote
		ctrl_demote(Customer,false)
	end

	def new_forum
		#puts "CustomerController.new_forum:id=#{params[:id]}"
		@object = Customer.find(params[:id])
		@types  = Typesobject.get_types("forum")
		@status = Statusobject.get_status("forum")
		@relation_id = params[:relation][:forum]
		respond_to do |format|
			flash[:notice] = ""
			@forum         = Forum.new(user: current_user)
			@forum.subject = t(:ctrl_subject_forum, :typeobj => t(:ctrl_customer), :ident => @object.ident)
			format.html { render :action => :new_forum, :id => @object.id }
			format.xml  { head :ok }
		end
	end

	def add_forum
		@object = Customer.find(params[:id])
		ctrl_add_forum(@object)
	end

	def add_docs
		#puts "#{self.class.name}.#{__method__}:#{params.inspect}"
		@object_plm = Customer.find(params[:id])
		ctrl_add_objects_from_clipboardtes(@object_plm, :document)
	end

	def add_projects
		@object_plm = Customer.find(params[:id])
		ctrl_add_objects_from_clipboardtes(@object_plm, :project)
	end

	#
	# preparation du datafile a associer
	#
	def new_datafile
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Customer.find(params[:id])
		@datafile = Datafile.new({:user => current_user, :thecustomer => @object_plm})
		ctrl_new_datafile(@object_plm)
	end

	#
	# creation du datafile et association et liberation si besoin
	#
	def add_datafile
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@object_plm = Customer.find(params[:id])
		ctrl_add_datafile(@object_plm)
	end

	def show_design
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		#LOG.debug(fname){"myparams=#{@myparams.inspect}"}
		customer = Customer.find(params[:id])
		ctrl_show_design(customer, params[:type_model_id])
	end
	private

	def index_
		@object_plms = Customer.find_paginate({ :user=> current_user, :filter_types => params[:filter_types], :filter_types => params[:filter_page], :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
	end
end
