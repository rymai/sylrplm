# frozen_string_literal: true

class SequencesController < ApplicationController
  include Controllers::PlmObjectController
  access_control Access.find_for_controller(controller_name.classify)
  # GET /sequences
  # GET /sequences.xml
  def index
    ctrl_index
  end

  def index
    index_
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @sequences }
    end
  end

  def index_
    @sequences = Sequence.find_paginate(user: current_user, filter_types: params[:filter_types], page: params[:page], query: params[:query], sort: params[:sort], nb_items: get_nb_items(params[:nb_items]))
    @object_plms = @sequences
  end

  def index_execute
    ctrl_index_execute
  end

  # GET /sequences/1
  # GET /sequences/1.xml
  def show
    show_
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @sequence }
    end
  end

  # GET /sequences/new
  # GET /sequences/new.xml
  def new
    @sequence = Sequence.new
    # @objects=Sequence.getObjectsWithSequence
    @utilities = html_models_and_columns(@sequence.utility)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @sequence }
    end
  end

  def new_dup
    fname = "#{self.class.name}.#{__method__}"
    @object_orig = Sequence.find(params[:id])
    @object = @object_orig.duplicate(current_user)
    @sequence = @object
    @utilities = html_models_and_columns(@sequence.utility)
    respond_to do |format|
      format.html
      format.xml { render xml: @object }
    end
  end

  # GET /sequences/1/edit
  def edit
    fname = "#{self.class.name}.#{__method__}"
    @sequence = Sequence.find(params[:id])
    # @objects=Sequence.getObjectsWithSequence
    @utilities = html_models_and_columns(@sequence.utility)
  end

  # POST /sequences
  # POST /sequences.xml
  def create
    @sequence = Sequence.new(params[:sequence])
    # @objects=Sequence.getObjectsWithSequence
    @utilities = html_models_and_columns(@sequence.utility)
    respond_to do |format|
      if fonct_new_dup?
        object_orig = Sequence.find(params[:object_orig_id])
        st = @sequence.create_duplicate(object_orig)
      else
        st = @sequence.save
      end
      if st
        flash[:notice] = t(:ctrl_object_created, typeobj: t(:ctrl_sequence), ident: @sequence.utility)
        params[:id] = @sequence.id
        show_
        format.html { render action: 'show' }
        format.xml  { render xml: @sequence, status: :created, location: @sequence }
      else
        flash[:error] = t(:ctrl_object_not_created, typeobj: t(:ctrl_sequence), ident: @sequence.utility, msg: nil)
        format.html { render action: 'new' }
        format.xml  { render xml: @sequence.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sequences/1
  # PUT /sequences/1.xml
  def update
    @sequence = Sequence.find(params[:id])
    # @objects=Sequence.getObjectsWithSequence
    @utilities = html_models_and_columns(@sequence.utility)
    @sequence.update_accessor(current_user)
    respond_to do |format|
      if @sequence.update_attributes(params[:sequence])
        flash[:notice] = t(:ctrl_object_updated, typeobj: t(:ctrl_sequence), ident: @sequence.utility)
        show_
        format.html { render action: 'show' }
        format.xml  { head :ok }
      else
        flash[:error] = t(:ctrl_object_not_updated, typeobj: t(:ctrl_sequence), ident: @sequence.utility, error: @role.errors.full_messages)
        format.html { render action: 'edit' }
        format.xml  { render xml: @sequence.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sequences/1
  # DELETE /sequences/1.xml
  def destroy_old
    @sequence = Sequence.find(params[:id])
    if @sequence.destroy
      flash[:notice] = t(:ctrl_object_deleted, typeobj: t(:ctrl_sequence), ident: @sequence.utility)
    else
      flash[:error] = t(:ctrl_object_not_deleted, typeobj: t(:ctrl_sequence), ident: @sequence.utility)
    end
    respond_to do |format|
      format.html { redirect_to(sequences_url) }
      format.xml { head :ok }
    end
  end

  private

  def show_
    @sequence = Sequence.find(params[:id])
  end
end
