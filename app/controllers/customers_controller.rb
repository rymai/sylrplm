class CustomersController < ApplicationController
	include Controllers::PlmObjectControllerModule
	before_filter :check_init, :only => :new

	access_control(Access.find_for_controller(controller_class_name))
	before_filter :check_user, :only => [:new, :edit]
	# GET /customers
	# GET /customers.xml
	def index
		index_
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @customers[:recordset] }
		end
	end

	# GET /customers/1
	# GET /customers/1.xml
	def show
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @customer }
		end
	end

	def select_view
		show_
		respond_to do |format|
			format.html { render :action => "show" }
			format.xml  { render :xml => @customer }
		end
	end

	def show_
		define_view
		@customer                = Customer.find(params[:id])
		@relations               = Relation.relations_for(@customer)
		@documents               = @customer.documents
		@projects                = @customer.projects
		@tree         						= build_tree(@customer, @myparams[:view_id])
		@tree_up      						= build_tree_up(@customer, @myparams[:view_id] )
	end

	# GET /customers/new
	# GET /customers/new.xml
	def new
		#puts "===CustomersController.new:"+params.inspect+" user="+@current_user.inspect
		@customer = Customer.new(user: current_user)
		@types    = Typesobject.get_types("customer")
		@status   = Statusobject.find_for("customer", 2)
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @customer }
		end
	end

	# GET /customers/1/edit
	def edit
		@customer = Customer.find_edit(params[:id])
		@types    = Typesobject.get_types("customer")
		@status   = Statusobject.find_for(@customer)
	end

	# POST /customers
	# POST /customers.xml
	def create
		@customer = Customer.new(params[:customer].merge(user: @current_user))
		@types    = Typesobject.get_types("customer")
		@status   = Statusobject.find_for(@customer)
		respond_to do |format|
			if @customer.save
				flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_customer), :ident => @customer.ident)
				format.html { redirect_to(@customer) }
				format.xml  { render :xml => @customer, :status => :created, :location => @customer }
			else
				flash[:notice] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_customer), :msg => nil)
				format.html { render :action => :new }
				format.xml  { render :xml => @customer.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /customers/1
	# PUT /customers/1.xml
	def update
		@customer = Customer.find(params[:id])
		@types    = Typesobject.get_types(:customer)
		@status   = Statusobject.find_for(@customer)
		@customer.update_accessor(current_user)
		respond_to do |format|
			if @customer.update_attributes(params[:customer])
				flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_customer), :ident => @customer.ident)
				format.html { redirect_to(@customer) }
				format.xml  { head :ok }
			else
				flash[:notice] = t(:ctrl_object_notupdated, :typeobj => t(:ctrl_customer), :ident => @customer.ident)
				format.html { render :action => :edit }
				format.xml  { render :xml => @customer.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /customers/1
	# DELETE /customers/1.xml
	def destroy
		@customer = Customer.find(params[:id])
		respond_to do |format|
			unless @customer.nil?
			if @customer.destroy
				flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_customer), :ident => @customer.ident)
				format.html { redirect_to(customers_url) }
				format.xml  { head :ok }
			else
				flash[:notice] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_customer), :ident => @customer.ident)
				index_
				format.html { render :action => "index" }
				format.xml  { render :xml => @customer.errors, :status => :unprocessable_entity }
			end
		else
			flash[:notice] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_customer), :ident => @customer.ident)
		end
		end
	end

	def promote
		ctrl_promote(Customer,false)
	end

	def demote
		ctrl_demote(Customer,false)
	end

	def new_forum
		#puts "CustomerController.new_forum:id=#{params[:id]}"
		@object = Customer.find(params[:id])
		@types  = Typesobject.find_for("forum")
		@status = Statusobject.find_for("forum")
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
		puts "#{self.class.name}.#{__method__}:#{params.inspect}"
		@customer = Customer.find(params[:id])
		ctrl_add_objects_from_favorites(@customer, :document)
	end

	def add_projects
		@customer = Customer.find(params[:id])
		ctrl_add_objects_from_favorites(@customer, :project)
	end

	def empty_favori
		puts "#{self.class.name}.#{__method__}:#{params.inspect}"
		empty_favori_by_type(get_model_type(params))
	end

	private

	def index_
		@customers = Customer.find_paginate({ :user=> current_user, :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
	end

	def create_tree_old(obj)
		tree = Tree.new( { :js_name=>"tree_down", :label => t(:ctrl_object_explorer, :typeobj => t(:ctrl_customer)), :open => true })
		session[:tree_object] = obj
		follow_tree_customer(tree, obj)
		tree
	end
end
