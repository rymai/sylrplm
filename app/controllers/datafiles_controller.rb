require 'net/http'



class DatafilesController < ApplicationController
  include Controllers::PlmObjectControllerModule
  before_filter :check_user, :only => [:new, :edit]
  # GET /datafiles
  # GET /datafiles.xml
  def index
    @datafiles = Datafile.find_paginate({ :user=> current_user,:page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
    #pour voir la liste des fichiers stockes sur le fog
    ####dirs=SylrplmFog.instance.directories(true) if admin_logged_in?
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @datafiles[:recordset] }
    end
  end

  # GET /datafiles/1
  # GET /datafiles/1.xml
  def show
    @datafile = Datafile.find(params[:id])
    @types    = Typesobject.find_for("datafile")
    if params["doc"]
      @document = Document.find(params["doc"])
      puts "datafiles_controller.show:doc=#{@document.inspect}"
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @datafile }
    end
  end

  # GET /datafiles/new
  # GET /datafiles/new.xml
  def new
    @datafile = Datafile.new(user: current_user)
    @types    = Typesobject.find_for("datafile")
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @datafile }
    end
  end

  # GET /datafiles/1/edit
  def edit
    @datafile = Datafile.find(params[:id])
    @types    = Typesobject.find_for("datafile")
    @document = Document.find(params["doc"]) if params["doc"]
  end

  # POST /datafiles
  # POST /datafiles.xml
  def create
    uploadedfile = parameters.delete(:uploaded_file)
    @datafile = Datafile.new(params.merge(user: current_user))
    @types    = Typesobject.find_for("datafile")
    @document = Document.find(params["doc"]) if params["doc"]
    puts "datafiles_controller.create:errors=#{@datafile.errors.inspect}"
    respond_to do |format|
      if @datafile.save
        @datafile.create_dir
        if uploadedfile
          @datafile.update_attributes(:uploaded_file => uploadedfile)
        end

        flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_datafile), :ident => @datafile.ident)
        format.html { redirect_to(@datafile) }
        format.xml  { render :xml => @datafile, :status => :created, :location => @datafile }
      else
        flash[:notice] = t(:ctrl_object_not_created,:typeobj => t(:ctrl_datafile), :msg => nil)
        format.html { render :action => "new" }
        format.xml  { render :xml => @datafile.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /datafiles/1
  # PUT /datafiles/1.xml
  def update
    @datafile = Datafile.find(params[:id])
    @types    = Typesobject.find_for("datafile")
    @document = Document.find(params["doc"]) if params["doc"]
    update_accessor(@datafile)
    respond_to do |format|
      if @datafile.update_attributes_repos(params, @current_user)
        flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_datafile), :ident => @datafile.ident)
        format.html { redirect_to(@datafile) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_datafile), :ident => @datafile.ident)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @datafile.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /datafiles/1
  # DELETE /datafiles/1.xml
  def destroy
    @datafile = Datafile.find(params[:id])
    if params["doc"]
      @document = Document.find(params["doc"])
    @document.remove_datafile(@datafile)
    end
    @datafile.delete
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
    send_file_content("inline")
  end

  def download_file
    send_file_content("attachment")
  end

private

  def send_file_content(disposition)
    @datafile = Datafile.find(params[:id])
    ret=nil
    begin
      content=@datafile.read_file
      puts "datafiles_controller.send_file_content"+content.length.to_s
      send_data(content,
              :filename => @datafile.filename,
              :type => @datafile.content_type,
              :disposition => disposition)
      ret=@datafile.filename
    rescue Exception => e
      respond_to do |format|
        flash[:notice] = t(:ctrl_object_not_found,:typeobj => t(:ctrl_datafile),  :ident => @datafile.ident)
        format.html { render :action => "show" }
        format.xml  { render :xml => @datafile.errors, :status => :unprocessable_entity }
      end
    end
    ret
  end

end
