class QuestionsController < ApplicationController
	include Controllers::PlmObjectControllerModule

	skip_before_filter :authorize

	access_control (Access.find_for_controller(controller_class_name()))
	def index
		@faqs = Question.find_paginate({:user=> current_user, :filter_types => params[:filter_types],:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
	end

	def show
		show_
	end

	def new
		@faq = Question.new(user: current_user)
		respond_to do |format|
			unless @faq.nil?
				format.html # new.html.erb
				format.xml  { render :xml => @faq }
			else
				flash[:error] =t(:ctrl_object_not_created, :typeobj =>t(:ctrl_faq), :msg => nil)
				format.html { redirect_to :controller => :questions, :action => :index }
				format.xml  { head :ok }
			end
		end
	end

	def create
		@faq = Question.new(params[:question])
		respond_to do |format|
			if @faq.save
				flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_faq),:ident=>@faq.id)
				params[:id]=@faq.id
				show_
				format.html { render :action => "show" }
				format.xml  { render :xml => @faq, :status => :created, :location => @faq }
			else
				flash[:error] =t(:ctrl_object_not_created, :typeobj =>t(:ctrl_faq), :msg => nil)
				format.html { render :action => :new }
				format.xml  { render :xml => @faq.errors, :status => :unprocessable_entity }
			end
		end

	end

	def edit
		@faq = Question.find(params[:id])
	end

	def update
		#puts "questions_controller.update:"+params.inspect
		@faq = Question.find(params[:id])
		@faq.update_accessor(current_user)
		respond_to do |format|
			if @faq.update_from_params(params[:question], current_user)
				flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_faq),:ident=>@faq.id)
				show_
				format.html { render :action => "show" }
				format.xml  { head :ok }
			else
				flash[:error] = t(:ctrl_object_notupdated,:typeobj =>t(:ctrl_faq),:ident=>@faq.controller)
				format.html { render :action => :edit }
				format.xml  { render :xml => @faq.errors, :status => :unprocessable_entity }
			end
		end
	end

	def destroy
		@faq = Question.find params[:id]
		id=@faq.id
		if @faq.destroy
			flash[:message] = flash[:notice] = t(:ctrl_object_deleted,:typeobj =>t(:ctrl_faq),:ident=>id)
		else
			flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_faq), :ident => id)
		end
		respond_to do |format|
			format.html { redirect_to(:questions) }
			format.xml  { head :ok }
		end
	end

private

	def show_
		@faq = Question.find params[:id]
	end

end
