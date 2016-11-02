require 'net/http'
require 'classes/filedrivers'

class DatafilesController < ApplicationController
	include Controllers::PlmObjectControllerModule
	# GET /datafiles
	# GET /datafiles.xml
	def index
		@datafiles = Datafile.find_paginate({ :user=> current_user, :filter_types => params[:filter_types],:page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
		#pour voir la liste des fichiers
		@all_files=Volume.get_all_files(true) if admin_logged_in?
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @datafiles[:recordset] }
		end
	end

	# GET /datafiles/1
	# GET /datafiles/1.xml
	def show
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect} flash=#{flash.inspect}"}
		show_
		LOG.debug(fname){"@datafile=#{@datafile.inspect} flash=#{flash.inspect}"}
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @datafile }
		end
	end

	def show_
		@datafile = Datafile.find(params[:id])
		@types    = Typesobject.get_types("datafile")
		if params["doc"]
			@object_plm = Document.find(params["doc"])
		#puts "datafiles_controller.show:doc(#{params["doc"]})=#{@object_plm} filedoc=#{@datafile.document}"
		end
	#puts "datafiles_controller.show:doc=#{@datafile.document} part=#{@datafile.part} project=#{@datafile.project} cust=#{@datafile.customer}"
	end

	# GET /datafiles/new
	# GET /datafiles/new.xml
	def new
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@datafile = Datafile.new(user: current_user)
		LOG.debug(fname){"new @datafile=#{@datafile.inspect}"}
		@types    = Typesobject.get_types("datafile")
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @datafile }
		end
	end

	# GET /datafiles/1/edit
	def edit
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@datafile = Datafile.find(params[:id])
		@types    = Typesobject.get_types("datafile")
	#TODO@object_plm = Document.find(params["doc"]) if params["doc"]
	end

	# POST /datafiles
	# POST /datafiles.xml
	def create
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@types    = Typesobject.get_types("datafile")
		@object_plm = Document.find(params["doc"]) if params["doc"]
		#puts "datafiles_controller.create:errors=#{@datafile.errors.inspect}"
		respond_to do |format|
			@datafile=Datafile.m_create(params)
			if @datafile.errors.empty?
				flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_datafile), :ident => @datafile.ident)
				params[:id]=@datafile.id
				show_
				format.html { render :action => "show" }
				format.xml  { render :xml => @datafile, :status => :created, :location => @datafile }
			else
				flash[:error] = t(:ctrl_object_not_created,:typeobj => t(:ctrl_datafile), :msg => @datafile.errors.full_messages)
				format.html { render :action => "new" }
				format.xml  { render :xml => @datafile.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /datafiles/1
	# PUT /datafiles/1.xml
	def update
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"update: params=#{params.inspect}"}
		@datafile = Datafile.find(params[:id])
		LOG.debug(fname){"update: revision=#{@datafile.revision}"}
		@types    = Typesobject.get_types("datafile")
		@object_plm = Document.find(params["doc"]) if params["doc"]
		stupd = @datafile.m_update(params, @current_user)
		respond_to do |format|
			if stupd && !@datafile.have_errors?
				LOG.debug(fname){"update: ok=#{@datafile.inspect}"}
				flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_datafile), :ident => @datafile.ident)
				show_
				format.html { render :action => "show" }
				format.xml  { head :ok }
			else
				LOG.error(fname){"update: ko stupd=#{stupd} errors=#{@datafile.errors.full_messages}"}
				flash[:error] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_datafile), :ident => @datafile.ident, :error => @datafile.errors.full_messages)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @datafile.errors, :status => :unprocessable_entity }
			end
		end
	end

	#
	# update of edit panel after changing the type
	#
	def update_type
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"params=#{params.inspect}"}
		@datafile = Datafile.find(params[:id])
		ctrl_update_type @datafile, params[:object_type]
	end

	# DELETE /datafiles/1
	# DELETE /datafiles/1.xml
	def destroy_old
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		@datafile = Datafile.find(params[:id])
		#if params["doc"]
		#	@object_plm = Document.find(params["doc"])
		#@object_plm.remove_datafile(@datafile)
		#end
		@datafile.m_destroy
		@types = Typesobject.get_types("datafile")
		respond_to do |format|
			if params["doc"]
				format.html { redirect_to(@object_plm) }
			else
				format.html { redirect_to(datafiles_url) }
			end
			format.xml  { head :ok }
		end
	end

	def show_file
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		send_file_content("inline")
	end

	def download_file
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname){"params=#{params.inspect}"}
		send_file_content("attachment")
	end

	private

	def send_file_content(disposition)
		fname= "#{self.class.name}.#{__method__}"
		error=nil
		begin
			@datafile = Datafile.find(params[:id])
			tool = @datafile.typesobject.get_fields_values_by_key("tool")
			LOG.debug(fname){"datafile=#{@datafile} tool=#{tool} disposition=#{disposition}"}
			#puts "datafiles_controller.send_file_content:"+fields.inspect
			if disposition == "inline"
				#
				# show_file: inline
				#
				unless tool.nil?
					#
					# show_file: inline with a tool
					#
					begin
						repos = @datafile.write_file_tmp
						dirtmpfile = File.join(RAILS_ROOT,repos)
						cmd = "#{tool} #{dirtmpfile} &"
						#LOG.debug(fname){"tool=#{tool} cmd=#{cmd}"}
						system(cmd)
						flash[:notice] = "File showed with tool #{tool}"
						respond_to do |format|
							format.html { render :action => "show" }
							format.xml  { format.xml  { head :ok } }
						end
					rescue Exception => e
						flash[:notice] = "Tool #{tool} does not work"
						content = @datafile.read_file_for_download
						#LOG.debug(fname){"content.length=#{content.length}"}
						error = ctrl_send_data(content, @datafile.filename, @datafile.content_type, disposition)
					end
				else
				#
				# show_file: inline without a tool
				#
					content = @datafile.read_file_for_download
					unless content.blank?
						# show_file: inline without tool: send_data inline
						error = ctrl_send_data(content, @datafile.filename, @datafile.content_type, disposition)
					else
						error = "File is empty"
					end
				end
			else
			#
			# download:attachement: send_file attachement
			#
				zipFileInfo=@datafile.zipFile
				if zipFileInfo[:size] > 0
					error = ctrl_send_file(zipFileInfo, disposition)
				else
					error = "File is empty"
				end
			end
		rescue ActiveRecord::RecordNotFound => e
			error= "Datafile not found:#{e.inspect}"
		end
		#

		unless error.nil?
			flash={} if flash.nil?
			flash[:notice]=error
			flash[:error]=error
			LOG.debug(fname){"flash=#{flash.inspect}"}
			respond_to do |format|
				unless @datafile.nil?
					format.html { render :action => "show" }
					format.xml  { render :xml => @datafile.errors, :status => :unprocessable_entity }
				else
					format.html { redirect_to_main }
				end
			end
		end
		flash
	end

	def ctrl_send_data(content, filename, content_type, disposition)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"content.length=#{content.length} filename=#{filename} content_type=#{content_type} disposition=#{disposition} "}
		error=nil
		begin
			send_data(content,
	              :filename => filename,
	              :type => content_type,
	              :disposition => disposition)
		rescue Exception => e
			LOG.error " error="+e.inspect
			e.backtrace.each {|x| LOG.error x}
			error = t(:ctrl_object_not_found,:typeobj => t(:ctrl_datafile),  :ident => @datafile.ident)
		end
		error
	end

	def ctrl_send_file(tmpfile, disposition)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname){"size=#{tmpfile[:size]} tmpfile=#{tmpfile[:file].path} filename=#{tmpfile[:filename]} content_type=#{tmpfile[:content_type]} disposition=#{disposition} "}
		error=nil
		begin
			if tmpfile[:size] > 0
				send_file(tmpfile[:file].path,
	              :filename => tmpfile[:filename],
	              :type => tmpfile[:content_type],
	              :disposition => disposition)
			end
		rescue Exception => e
			LOG.error " error="+e.inspect
			e.backtrace.each {|x| LOG.error x}
			error = t(:ctrl_object_not_found,:typeobj => t(:ctrl_datafile),  :ident => @datafile.ident)
		end
		error
	end

end
