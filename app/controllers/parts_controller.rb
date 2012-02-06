class PartsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  before_filter :check_init, :only => :new
  access_control(Access.find_for_controller(controller_class_name))
  before_filter :check_user, :only => [:new, :edit]
  # GET /parts
  # GET /parts.xml
  def index
    index_
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @parts[:recordset] }
    end
  end

  # GET /parts/1
  # GET /parts/1.xml
  def show
    @part                    = Part.find(params[:id])
    @relations               = Relation.relations_for(@part)
    @other_parts = Part.paginate(:page => params[:page],
    :conditions => ["id != #{@part.id}"],
    :order => 'ident ASC',
    :per_page => cfg_items_per_page)
    @first_status = Statusobject.get_first("part")

    @tree         = create_tree(@part)
    @tree_up      = create_tree_up(@part)

    @documents = @part.documents
    @parts     = @part.parts
    @projects  = @part.projects

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @part }
    end
  end

  # GET /parts/new
  # GET /parts/new.xml
  def new
    #puts "===PartsController.new:"+params.inspect+" user="+@current_user.inspect
    @part = Part.create_new(nil, @current_user)
    @types= Part.get_types_part
    @status= Statusobject.find_for("part", 2)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @part }
    end
  end

  # GET /parts/1/edit
  def edit
    @part = Part.find_edit(params[:id])
    @types=Part.get_types_part
    #seulement les statuts qui peuvenet etre promus sans process
    @status= Statusobject.find_for("part", 2)
  end

  # POST /parts
  # POST /parts.xml
  def create
    puts "===PartsController.create:"+params.inspect
    @part = Part.create_new(params[:part], @current_user)
    @types=Part.get_types_part
    @status= Statusobject.find_for("part")
    respond_to do |format|
      puts "===PartsController.create:"+@part.inspect
      if @part.save
        puts "===PartsController.create:ok:"+@part.inspect
        flash[:notice] = t(:ctrl_object_created,:typeobj =>t(:ctrl_part),:ident=>@part.ident)
        format.html { redirect_to(@part) }
        format.xml  { render :xml => @part, :status => :created, :location => @part }
      else
        puts "===PartsController.create:ko:"+@part.inspect
        flash[:notice] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_part), :msg => nil)
        format.html { render :action => "new" }
        format.xml  { render :xml => @part.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /parts/1
  # PUT /parts/1.xml
  def update
    @part = Part.find(params[:id])
    @part.update_accessor(current_user)
    respond_to do |format|
      if @part.update_attributes(params[:part])
        flash[:notice] = t(:ctrl_object_updated,:typeobj =>t(:ctrl_part),:ident=>@part.ident)
        format.html { redirect_to(@part) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_part),:ident=>@part.ident)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @part.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /parts/1
  # DELETE /parts/1.xml
  def destroy
    @part = Part.find(params[:id])
    respond_to do |format|
      unless @part.nil?
        if @part.destroy
          flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_part), :ident => @part.ident)
          format.html { redirect_to(parts_url) }
          format.xml  { head :ok }
        else
          flash[:notice] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_part), :ident => @part.ident)
          index_
          format.html { render :action => "index" }
          format.xml  { render :xml => @part.errors, :status => :unprocessable_entity }
        end
      else
        flash[:notice] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_part), :ident => @part.ident)
      end
    end
  end

  def revise
    ctrl_revise(Part)
  end

  def add_docs
    @part = Part.find(params[:id])
    ctrl_add_objects_from_favorites(@part, :document)
  end

  def add_parts
    @part = Part.find(params[:id])
    ctrl_add_objects_from_favorites(@part, :part)
  end

  def new_forum
    puts 'PartController.new_forum:part_id='+params[:id]
    @object = Part.find(params[:id])
    @types=Typesobject.find_for("forum")
    @status= Statusobject.find_for("forum")
    @relation_id = params[:relation][:forum]
    respond_to do |format|
      flash[:notice] = ""
      @forum=Forum.create_new(nil, current_user)
      @forum.subject=t(:ctrl_subject_forum,:typeobj =>t(:ctrl_part),:ident=>@object.ident)
      format.html {render :action=>:new_forum, :id=>@object.id }
      format.xml  { head :ok }
    end
  end

  def add_forum
    @part = Part.find(params[:id])
    ctrl_add_forum(@part)
  end

  def promote
    @part = Part.find(params[:id])
    ctrl_promote(@part)
  end

  def demote
    @part = Part.find(params[:id])
    ctrl_demote(@part)
  end

  private

  def index_
    @parts = Part.find_paginate({ :user=> current_user, :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
  end

  #  Now the explanation: The above code is constructing a navigation tree for a two-level hierarchy with a Parent Model
  #  and a Child Model.
  #  The Child Model has a parent_id attribute linking to the Parent table.
  #  The default action when someone clicks on any node on the tree is to call the show Action for that node.
  #  This is done by setting the pnode.link_to_remote and cnode.link_to_remote with the parameters as above.
  #  The update attribute points to the div of the view to be updated when the node is clicked in the tree.
  #  The base attribute is very important since that reference is used internally in the railstree plugin to
  #  callback so it better be not null.
  def create_tree(part)
    tree = Tree.new({:js_name=>"tree_down", :label=>t(:ctrl_object_explorer,:typeobj =>t(:ctrl_part)),:open => true})
    session[:tree_object]=part
    follow_tree_part(tree, part)
    tree
  end

  def create_tree_up(part)
    tree = Tree.new({:js_name=>"tree_up", :label=>t(:ctrl_object_referencer,:typeobj =>t(:ctrl_part)),:open => true})
    session[:tree_object]=part
    follow_tree_up_part(tree, part)
    tree
  end

end
