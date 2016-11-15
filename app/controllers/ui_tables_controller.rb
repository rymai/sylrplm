class UiTablesController < ApplicationController
	include Controllers::PlmObjectControllerModule
	respond_to :html, :js, :json, :xml
	access_control(Access.find_for_controller(controller_name.classify))

	before_action :set_ui_table, only: [:show, :edit, :update, :destroy]
	#
	# GET /ui_tables
	# GET /ui_tables.json
	def index
		fname= "#{self.class.name}.#{__method__}"
		@ui_tables = UiTable.find_paginate({:user=> current_user, :filter_types => params[:filter_types],:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
	end

	# GET /ui_tables/1
	# GET /ui_tables/1.json
	def show
		fname= "#{self.class.name}.#{__method__}"
	end

	# GET /ui_tables/new
	def new
		fname = "#{self.class.name}.#{__method__}"
		@ui_table = UiTable.new
		@columns=UiColumn.all.to_a
		LOG.debug (fname){"@ui_table=#{@ui_table}"}
		LOG.debug (fname){"@columns=#{@columns}"}
	end

	def new_dup
		fname= "#{self.class.name}.#{__method__}"
		@object_orig = UiTable.find(params[:id])
		@object = @object_orig.duplicate(current_user)
		@ui_table=@object
		@columns=UiColumn.all.to_a
		respond_to do |format|
			format.html
			format.xml  { render :xml => @object }
		end
	end
	# GET /ui_tables/1/edit
	def edit
		fname= "#{self.class.name}.#{__method__}"
		@columns=UiColumn.all.to_a
	end

	# POST /ui_tables
	# POST /ui_tables.json
	def create
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params[:ui_table]=#{params[:ui_table]}"}
		@ui_table = UiTable.new(params[:ui_table])
		@columns=UiColumn.all.to_a
		respond_to do |format|
			cols=@ui_table.ui_columns_exists?(params[:ui_table][:ui_columns])
			if cols
				if @ui_table.save
					#unless params[:ui_column_ids].nil?
					#para=params[:ui_column_ids].zip(params[:rank] )
					#end
					#@ui_table.update_relation_attributes(para)
					format.html { redirect_to @ui_table, notice: 'Ui table was successfully created.' }
					format.json { render :show, status: :created, location: @ui_table }
				else
					format.html { render :new }
					format.json { render json: @ui_table.errors, status: :unprocessable_entity }
				end
			else
				format.html { render :edit }
				format.json { render json: @ui_table.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /ui_tables/1
	# PATCH/PUT /ui_tables/1.json
	def update
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params}"}
		LOG.debug(fname){"ui_table_params=#{ui_table_params}"}
		#LOG.debug(fname){params["ui_column_ids"].zip(params["rank"])}
		respond_to do |format|
			cols=@ui_table.ui_columns_exists?(params[:ui_table][:ui_columns])
			if cols
				if @ui_table.update(params[:ui_table])
					format.html { redirect_to @ui_table, notice: 'Ui table was successfully updated. update rank of columns=#{st}' }
					format.json { render :show, status: :ok, location: @ui_table }
				else
					format.html { render :edit }
					format.json { render json: @ui_table.errors, status: :unprocessable_entity }
				end
			else
				format.html { render :edit }
				format.json { render json: @ui_table.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /ui_tables/1
	# DELETE /ui_tables/1.json
	def destroy
		fname= "#{self.class.name}.#{__method__}"
		@ui_table.destroy
		respond_to do |format|
			format.html { redirect_to ui_tables_url, notice: 'Ui table was successfully destroyed.' }
			format.json { head :no_content }
		end
	end

	private

	# Use callbacks to share common setup or constraints between actions.
	def set_ui_table
		fname= "#{self.class.name}.#{__method__}"
		@ui_table = UiTable.find(params[:id])
		@columns=UiColumn.all.to_a
	end

	# Never trust parameters from the scary internet, only allow the white list through.
	def ui_table_params
		fname= "#{self.class.name}.#{__method__}"
		params.require(:ui_table).permit(:ident, :type_table, :description, :pagination, :domain)
	end
end
