require 'net/http'
class DatafilesController < ApplicationController
  include Controllers::PlmObjectControllerModule

  # GET /datafiles
  # GET /datafiles.xml
  def index
    @datafiles = Datafile.find_paginate({ :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
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
    @datafile = Datafile.create_new(nil, @user)
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
    @datafile = Datafile.create_new(params, @user)
    @types    = Typesobject.find_for("datafile")
    @document = Document.find(params["doc"]) if params["doc"]
    puts "datafiles_controller.create:errors=#{@datafile.errors.inspect}"
    respond_to do |format|
      if @datafile
        flash[:notice] = t(:ctrl_object_created, :object => t(:ctrl_datafile), :ident => @datafile.ident)
        format.html { redirect_to(@datafile) }
        format.xml  { render :xml => @datafile, :status => :created, :location => @datafile }
      else
        flash[:notice] = t(:ctrl_object_not_created,:object => t(:ctrl_datafile))
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
    respond_to do |format|
      if @datafile.update_attributes_repos(params, @user)
        flash[:notice] = t(:ctrl_object_updated, :object => t(:ctrl_datafile), :ident => @datafile.ident)
        format.html { redirect_to(@datafile) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_updated, :object => t(:ctrl_datafile), :ident => @datafile.ident)
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
    @datafile.destroy
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
    @datafile = Datafile.find(params[:id])
    send_data(@datafile.read_file,
              :filename => @datafile.filename,
              :type => @datafile.content_type,
              :disposition => "inline")
  end

  def download_file
    @datafile = Datafile.find(params[:id])
    send_data(@datafile.read_file,
              :filename => @datafile.filename,
              :type => @datafile.content_type,
              :disposition => "attachment")
    @datafile.filename
  end

  def show_file_data
    @datafile = Datafile.find(params[:id])
    send_data(@datafile.data,
              :filename => @datafile.filename,
              :type => @datafile.content_type,
              :disposition => "inline")
  end

end