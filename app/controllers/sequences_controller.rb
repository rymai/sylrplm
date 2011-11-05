class SequencesController < ApplicationController
  include Controllers::PlmObjectControllerModule
  access_control (Access.find_for_controller(controller_class_name()))
  # GET /sequences
  # GET /sequences.xml
  def index
   @sequences = Sequence.find_paginate({:user=> current_user,:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})  
     respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sequences }
    end
  end
  
  # GET /sequences/1
  # GET /sequences/1.xml
  def show
    @sequence = Sequence.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sequence }
    end
  end
  
  # GET /sequences/new
  # GET /sequences/new.xml
  def new
    @sequence = Sequence.new
    #@objects=Sequence.getObjectsWithSequence
    @utilities=html_models_and_columns(@sequence.utility)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @sequence }
    end
  end
  
  # GET /sequences/1/edit
  def edit
    @sequence = Sequence.find(params[:id])
    #@objects=Sequence.getObjectsWithSequence
    @utilities=html_models_and_columns(@sequence.utility)
    
  end
  
  # POST /sequences
  # POST /sequences.xml
  def create
    @sequence = Sequence.new(params[:sequence])
    #@objects=Sequence.getObjectsWithSequence
    @utilities=html_models_and_columns(@sequence.utility)
    respond_to do |format|
      if @sequence.save
        flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_sequence),:ident=>@sequence.utility)
        format.html { redirect_to(@sequence) }
        format.xml  { render :xml => @sequence, :status => :created, :location => @sequence }
      else
        flash[:notice] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_sequence),:ident=>@sequence.utility, :msg => nil)
        format.html { render :action => "new" }
        format.xml  { render :xml => @sequence.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /sequences/1
  # PUT /sequences/1.xml
  def update
    @sequence = Sequence.find(params[:id])
    #@objects=Sequence.getObjectsWithSequence
    @utilities=html_models_and_columns(@sequence.utility)
    @sequence.update_accessor(current_user)
    respond_to do |format|
      if @sequence.update_attributes(params[:sequence])
        flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_sequence),:ident=>@sequence.utility)
        format.html { redirect_to(@sequence) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_sequence),:ident=>@sequence.utility)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sequence.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /sequences/1
  # DELETE /sequences/1.xml
  def destroy
    @sequence = Sequence.find(params[:id])
    @sequence.destroy
    respond_to do |format|
      flash[:notice] = t(:ctrl_object_deleted,:typeobj =>t(:ctrl_sequence),:ident=>@sequence.utility)
      format.html { redirect_to(sequences_url) }
      format.xml  { head :ok }
    end
  end
end
