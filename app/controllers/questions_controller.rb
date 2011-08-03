class QuestionsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  access_control (Access.find_for_controller(controller_class_name()))
  
  def index
    @faqs = Question.find_paginate({:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])}) 
  end
  
  def show
    @faq = Question.find params[:id]
  end
  
  def new
    @faq = Question.create_new
    respond_to do |format|
      #flash[:notice] = "#{@controllers.size()} controllers:1=#{@controllers[1].name}"
      format.html # new.html.erb
      format.xml  { render :xml => @faq }
    end
  end
  
  def create
    @faq = Question.new(params[:question])
    respond_to do |format|
      if @faq.save
        flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_faq),:ident=>@faq.id)
        format.html { redirect_to(@faq) }
        format.xml  { render :xml => @faq, :status => :created, :location => @faq }
      else
        flash[:notice] =t(:ctrl_object_not_created, :typeobj =>t(:ctrl_faq), :msg => nil)
        format.html { render :action => :new }
        format.xml  { render :xml => @faq.errors, :status => :unprocessable_entity }
      end
    end
    
    
  end
  
  def edit
    @faq = Question.find(params[:id])
  end
  
  def update
    @faq = Question.find(params[:id])
    respond_to do |format|
      if @faq.update_attributes(params[:question])
        flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_faq),:ident=>@faq.id)
        format.html { redirect_to(@faq) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_notupdated,:typeobj =>t(:ctrl_faq),:ident=>@faq.controller)
        format.html { render :action => :edit }
        format.xml  { render :xml => @faq.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @faq = Question.find params[:id]
    id=@faq.id
    @faq.destroy
    flash[:message] = flash[:notice] = t(:ctrl_object_deleted,:typeobj =>t(:ctrl_faq),:ident=>id)
    respond_to do |format|
      format.html { redirect_to(faqs_url) }
      format.xml  { head :ok }
    end
  end
end
