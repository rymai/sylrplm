class ForumsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  access_control(Access.find_for_controller(controller_class_name))
  before_filter :check_user, :only => [:new, :edit]
  # GET /forums
  # GET /forums.xml
  def index
    index_
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @forums }
    end
  end

  # GET /forums/1
  # GET /forums/1.xml
  def show
    @forum = Forum.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @forum }
    end
  end

  # GET /forums/new
  # GET /forums/new.xml
  def new
    @forum  = Forum.new
    @types  = Typesobject.find_for("forum")
    @status = Statusobject.find_for("forum")
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @forum }
    end
  end

  # GET /forums/1/edit
  def edit
    @forum  = Forum.find(params[:id])
    @types  = Typesobject.find_for("forum")
    @status = Statusobject.find_for("forum")
  end

  # POST /forums
  # POST /forums.xml
  def create
    @forum  = Forum.new(params[:forum].merge(user: current_user))
    @types  = Typesobject.find_for("forum")
    @status = Statusobject.find_for("forum")
    respond_to do |format|
      if @forum.save
        @item = @forum.forum_items.build(message: params[:message], user: current_user)
        if @item.save
          flash[:notice] = 'Forum and item was successfully created.'
          format.html { redirect_to(@forum) }
          format.xml  { render :xml => @forum, :status => :created, :location => @forum }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @forum.errors, :status => :unprocessable_entity }
        end
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @forum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /forums/1
  # PUT /forums/1.xml
  def update
    @forum = Forum.find(params[:id])
    @forum.update_accessor(current_user)
    respond_to do |format|
      if @forum.update_attributes(params[:forum])
        flash[:notice] = 'Forum was successfully updated.'
        format.html { redirect_to(@forum) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @forum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /forums/1
  # DELETE /forums/1.xml
  def destroy
    @forum = Forum.find(params[:id])
    respond_to do |format|
      unless @forum.nil?
        if @forum.destroy
          flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_forum), :ident => @forum.ident)
          format.html { redirect_to(forums_url) }
          format.xml  { head :ok }
        else
          flash[:notice] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_forum), :ident => @forum.ident)
          index_
          format.html { render :action => "index" }
          format.xml  { render :xml => @forum.errors, :status => :unprocessable_entity }
        end
      else
        flash[:notice] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_forum), :ident => @forum.ident)
      end
    end
  end

  private

  def index_
    @forums = Forum.find_paginate({ :user=> current_user,:page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
  end
end
