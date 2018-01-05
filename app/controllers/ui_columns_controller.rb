# frozen_string_literal: true

class UiColumnsController < ApplicationController
  include Controllers::PlmObjectController
  respond_to :html, :js, :json, :xml
  access_control(Access.find_for_controller(controller_name.classify))
  before_action :set_ui_column, only: [:show, :edit, :update, :destroy]
  # GET /ui_columns
  # GET /ui_columns.json
  def index
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "params=#{params}" }
    @ui_columns = UiColumn.find_paginate(user: current_user, filter_types: params[:filter_types], page: params[:page], query: params[:query], sort: params[:sort], nb_items: get_nb_items(params[:nb_items]))
  end

  # GET /ui_columns/1
  # GET /ui_columns/1.json
  def show
    fname = "#{self.class.name}.#{__method__}"
  end

  # GET /ui_columns/new
  def new
    fname = "#{self.class.name}.#{__method__}"
    @ui_column = UiColumn.new
  end

  def new_dup
    fname = "#{self.class.name}.#{__method__}"
    @object_orig = UiColumn.find(params[:id])
    @object = @object_orig.duplicate(current_user)
    @ui_column = @object
    respond_to do |format|
      format.html
      format.xml { render xml: @object }
    end
  end

  # GET /ui_columns/1/edit
  def edit
    fname = "#{self.class.name}.#{__method__}"
    @ui_tables = UiTable.all
  end

  # POST /ui_columns
  # POST /ui_columns.json
  def create
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "params column=#{params[:ui_column]}" }
    @ui_column = UiColumn.new(params[:ui_column])
    @ui_tables = UiTable.all
    respond_to do |format|
      if @ui_column.save
        format.html { redirect_to @ui_column, notice: 'Ui column was successfully created.' }
        format.json { render :show, status: :created, location: @ui_column }
      else
        format.html { render :new }
        format.json { render json: @ui_column.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ui_columns/1
  # PATCH/PUT /ui_columns/1.json
  def update
    fname = "#{self.class.name}.#{__method__}"
    respond_to do |format|
      if @ui_column.update(params[:ui_column])
        format.html { redirect_to @ui_column, notice: 'Ui column was successfully updated.' }
        format.json { render :show, status: :ok, location: @ui_column }
      else
        format.html { render :edit }
        format.json { render json: @ui_column.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ui_columns/1
  # DELETE /ui_columns/1.json
  def destroy
    fname = "#{self.class.name}.#{__method__}"
    @ui_column.destroy
    respond_to do |format|
      format.html { redirect_to ui_columns_url, notice: 'Ui column was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ui_column
    fname = "#{self.class.name}.#{__method__}"
    @ui_column = UiColumn.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def ui_column_params
    params.require(:ui_column).permit(:ident, :type, :description, :visible_user, :visible_admin, :visible_support, :editable, :type_show, :type_editable, :type_editable_file)
  end
end
