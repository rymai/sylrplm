require 'net/http'
require 'classes/filedrivers'

class DatafilesController < ApplicationController
	include Controllers::PlmObjectControllerModule
	# GET /datafiles
	# GET /datafiles.xml
	def index
		@datafiles = Datafile.find_paginate({ :user=> current_user,:page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
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
		#LOG.debug (fname){"params=#{params.inspect}"}
		@datafile = Datafile.find(params[:id])
		@types    = Typesobject.find_for("datafile")
		if params["doc"]
			@document = Document.find(params["doc"])
		#puts "datafiles_controller.show:doc(#{params["doc"]})=#{@document} filedoc=#{@datafile.document}"
		end
		#puts "datafiles_controller.show:doc=#{@datafile.document} part=#{@datafile.part} project=#{@datafile.project} cust=#{@datafile.customer}"
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @datafile }
		end
	end

	# GET /datafiles/new
	# GET /datafiles/new.xml
	def new
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"params=#{params.inspect}"}
		@datafile = Datafile.new(user: current_user)
		@types    = Typesobject.find_for("datafile")
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @datafile }
		end
	end

	# GET /datafiles/1/edit
	def edit
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"params=#{params.inspect}"}
		@datafile = Datafile.find(params[:id])
		@types    = Typesobject.find_for("datafile")
	#TODO@document = Document.find(params["doc"]) if params["doc"]
	end

	# POST /datafiles
	# POST /datafiles.xml
	def create
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"params=#{params.inspect}"}
		@types    = Typesobject.find_for("datafile")
		@document = Document.find(params["doc"]) if params["doc"]
		#puts "datafiles_controller.create:errors=#{@datafile.errors.inspect}"
		respond_to do |format|
			@datafile=Datafile.m_create(params[:datafile])
			if @datafile.errors.nil?
				flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_datafile), :ident => @datafile.ident)
				format.html { redirect_to(@datafile) }
				format.xml  { render :xml => @datafile, :status => :created, :location => @datafile }
			else
				flash[:error] = t(:ctrl_object_not_created,:typeobj => t(:ctrl_datafile), :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @datafile.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /datafiles/1
	# PUT /datafiles/1.xml
	def update
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"params=#{params.inspect}"}
		@datafile = Datafile.find(params[:id])
		@types    = Typesobject.find_for("datafile")
		@document = Document.find(params["doc"]) if params["doc"]
		stupd = @datafile.m_update(params, @current_user)
		respond_to do |format|
			if stupd && !@datafile.have_errors?
				flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_datafile), :ident => @datafile.ident)
				format.html { redirect_to(@datafile) }
				format.xml  { head :ok }
			else
			#LOG.debug (fname){"stupd=#{stupd} errors=#{@datafile.errors.inspect}"}
				flash[:error] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_datafile), :ident => @datafile.ident)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @datafile.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /datafiles/1
	# DELETE /datafiles/1.xml
	def destroy
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug (fname){"params=#{params.inspect}"}
		@datafile = Datafile.find(params[:id])
		#if params["doc"]
		#	@document = Document.find(params["doc"])
		#@document.remove_datafile(@datafile)
		#end
		@datafile.m_destroy
		@types = Typesobject.find_for("datafile")
		respond_to do |format|
			if params["doc"]
				format.html { redirect_to(@document) }
			else
				format.html { redirect_to(datafiles_url) }
			end
			format.xml  { head :ok }
		end
	end

	def show_file
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname){"params=#{params.inspect}"}
		send_file_content("inline")
	end

	def download_file
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname){"params=#{params.inspect}"}
		send_file_content("attachment")
	end

	private

	def send_file_content(disposition)
		fname= "#{self.class.name}.#{__method__}"
		@datafile = Datafile.find(params[:id])
		tool = @datafile.typesobject.get_fields_values("tool")
		LOG.debug (fname){"tool=#{tool} disposition=#{disposition}"}
		#puts "datafiles_controller.send_file_content:"+fields.inspect
		#
		# show_file: inline 
		#
		if disposition == "inline"
			unless tool.nil?
				# show_file: inline with a tool
				begin
					repos = @datafile.write_file_tmp
					dirtmpfile = File.join(RAILS_ROOT,repos)
					cmd = "#{tool} #{dirtmpfile} &"
					LOG.debug (fname){"tool=#{tool} cmd=#{cmd}"}
					system(cmd)
					flash[:info] = "File showed with tool #{tool}"
					respond_to do |format|
						format.html { render :action => "show" }
						format.xml  { format.xml  { head :ok } }
					end
				rescue Exception => e
					flash[:info] = "Tool #{tool} does not work"
					content = @datafile.read_file 
					#LOG.debug (fname){"content.length=#{content.length}"}
					flash = ctrl_send_data(content, @datafile.filename, @datafile.content_type, disposition)
				end
			else
				content = @datafile.read_file 
				# show_file: inline without tool: send_data inline
				flash = ctrl_send_data(content, @datafile.filename, @datafile.content_type, disposition)
			end
		else
			# download:attachement: send_file attachement
			zipFileInfo=@datafile.zipFile
			flash = ctrl_send_file(zipFileInfo, disposition)
		end
		#
		flash
	end
	
	def ctrl_send_data(content, filename, content_type, disposition)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname){"content.length=#{content.length} filename=#{filename} content_type=#{content_type} disposition=#{disposition} "}
		begin
			send_data(content,
	              :filename => filename,
	              :type => content_type,
	              :disposition => disposition)
		rescue Exception => e
			LOG.error " error="+e.inspect
			e.backtrace.each {|x| LOG.error x}
			respond_to do |format|
				flash[:info] = t(:ctrl_object_not_found,:typeobj => t(:ctrl_datafile),  :ident => @datafile.ident)
				format.html { render :action => "show" }
				format.xml  { render :xml => @datafile.errors, :status => :unprocessable_entity }
			end
		flash
		end
	end
	
	def ctrl_send_file(tmpfile, disposition)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug (fname){"tmpfile=#{tmpfile[:file].path} filename=#{tmpfile[:filename]} content_type=#{tmpfile[:content_type]} disposition=#{disposition} "}
		begin
			send_file(tmpfile[:file].path,
	              :filename => tmpfile[:filename],
	              :type => tmpfile[:content_type],
	              :disposition => disposition)
		rescue Exception => e
			LOG.error " error="+e.inspect
			e.backtrace.each {|x| LOG.error x}
			respond_to do |format|
				flash[:info] = t(:ctrl_object_not_found,:typeobj => t(:ctrl_datafile),  :ident => @datafile.ident)
				format.html { render :action => "show" }
				format.xml  { render :xml => @datafile.errors, :status => :unprocessable_entity }
			end
		flash
		end
	end
	
end
