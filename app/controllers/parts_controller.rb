class PartsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  include Controllers::PlmInitControllerModule
  before_filter :check_init, :only => :new
  access_control(Access.find_for_controller(controller_class_name))

  # GET /parts
  # GET /parts.xml
  def index
    @parts = Part.find_paginate({ :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @parts[:recordset] }
    end
  end

  # GET /parts/1
  # GET /parts/1.xml
  def show
    @relation_types_document = Typesobject.get_types_names(:relation_document)
    @relation_types_part     = Typesobject.get_types_names(:relation_part)
    @part                    = Part.find(params[:id])
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
    @part = Part.create_new(nil, @user)
    @types= Part.get_types_part
    @status= Statusobject.find_for("part")
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @part }
    end
  end

  # GET /parts/1/edit
  def edit
    @part = Part.find_edit(params[:id])
    @types=Part.get_types_part
    @status= Statusobject.find_for("part")
  end

  # POST /parts
  # POST /parts.xml
  def create
    @part = Part.create_new(params[:part], @user)
    @types=Part.get_types_part
    @status= Statusobject.find_for("part")
    respond_to do |format|
      if @part.save
        flash[:notice] = t(:ctrl_object_created,:object=>t(:ctrl_part),:ident=>@part.ident)
        format.html { redirect_to(@part) }
        format.xml  { render :xml => @part, :status => :created, :location => @part }
      else
        flash[:notice] = t(:ctrl_object_not_created,:object=>t(:ctrl_part))
        format.html { render :action => "new" }
        format.xml  { render :xml => @part.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /parts/1
  # PUT /parts/1.xml
  def update
    @part = Part.find(params[:id])

    respond_to do |format|
      if @part.update_attributes(params[:part])
        flash[:notice] = t(:ctrl_object_updated,:object=>t(:ctrl_part),:ident=>@part.ident)
        format.html { redirect_to(@part) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_updated,:object=>t(:ctrl_part),:ident=>@part.ident)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @part.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /parts/1
  # DELETE /parts/1.xml
  def destroy
    @part = Part.find(params[:id])
    @part.destroy
    flash[:notice] = t(:ctrl_object_deleted,:object=>t(:ctrl_part),:ident=>@part.ident)
    respond_to do |format|
      format.html { redirect_to(parts_url) }
      format.xml  { head :ok }
    end
  end

  def revise
    ctrl_revise(Part)
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
    tree = Tree.new({:label=>t(:ctrl_object_explorer,:object=>t(:ctrl_part)),:open => true})
    session[:tree_object]=part
    follow_tree_part(tree, part, self)
    tree
  end

  def create_tree_up(part)
    tree = Tree.new({:label=>t(:ctrl_object_referencer,:object=>t(:ctrl_part)),:open => true})
    session[:tree_object]=part
    follow_tree_up_part(tree, part,self)
    tree
  end

  def add_docs
    @part = Part.find(params[:id])
    relation=params[:relation][:document]
    respond_to do |format|
      if @favori_document != nil
        flash[:notice] = ""
        params.each do |item|
          #flash[:notice]+="_"+item.to_s
        end
        @favori_document.items.each do |item|
          link_=Link.create_new("part", @part, "document", item, relation)
          link=link_[:link]
          if(link!=nil)
            if(link.save)
              flash[:notice] += t(:ctrl_object_added,:object=>t(:ctrl_document),:ident=>item.ident,:relation=>relation,:msg=>t(link_[:msg]))
            else
              flash[:notice] += t(:ctrl_object_not_added,:object=>t(:ctrl_document),:ident=>item.ident,:relation=>relation,:msg=>t(link_[:msg]))
            end
          else
            flash[:notice] += t(:ctrl_object_not_linked,:object=>t(:ctrl_document),:ident=>item.ident,:relation=>relation,:msg=>nil)
          end
        end
        reset_favori_document
      else
        flash[:notice] = t(:ctrl_nothing_to_paste,:object=>t(:ctrl_document))
      end
      format.html { redirect_to(@part) }
      format.xml  { head :ok }
    end
  end

  def add_parts
    @part = Part.find(params[:id])
    relation=params[:relation][:part]
    respond_to do |format|
      if @favori_part != nil
        flash[:notice] = ""
        @favori_part.items.each do |item|
          link_=Link.create_new("part", @part, "part", item, relation)
          link=link_[:link]
          if(link!=nil)
            if(link.save)
              flash[:notice] += t(:ctrl_object_added,:object=>t(:ctrl_part),:ident=>item.ident,:relation=>relation,:msg=>t(link_[:msg]))
            else
              flash[:notice] += t(:ctrl_object_not_added,:object=>t(:ctrl_part),:ident=>item.ident,:relation=>relation,:msg=>t(link_[:msg]))
            end
          else
            flash[:notice] += t(:ctrl_object_not_linked,:object=>t(:ctrl_part),:ident=>item.ident,:relation=>relation,:msg=>nil)
          end
        end
        reset_favori_part
      else
        flash[:notice] = t(:ctrl_nothing_to_paste,:object=>t(:ctrl_part))
      end
      format.html { redirect_to(@part) }
      format.xml  { head :ok }
    end
  end

  def new_forum
    puts 'PartController.new_forum:part_id='+params[:id]
    @object = Part.find(params[:id])
    @types=Typesobject.find_for("forum")
    @status= Statusobject.find_for("forum")
    respond_to do |format|
      flash[:notice] = ""
      @forum=Forum.create_new(nil)
      @forum.subject=t(:ctrl_subject_forum,:object=>t(:ctrl_part),:ident=>@object.ident)
      format.html {render :action=>:new_forum, :id=>@object.id }
      format.xml  { head :ok }
    end
  end

  def add_forum
    @part = Part.find(params[:id])
    ctrl_add_forum(@part,"part")
  end

  def add_forum_old
    @part = Part.find(params[:id])
    relation="forum"
    error=false
    respond_to do |format|
      flash[:notice] = ""
      @forum=Forum.new(params[:forum])
      @forum.creator=@user
      if(@forum.save)
        item=ForumItem.create_new(@forum, params)
        if(item.save)
          link_=Link.create_new("part", @part, "forum", @forum, relation)
          link=link_[:link]
          if(link!=nil)
            if(link.save)
              #flash[:notice] += "<br> forum #{@forum.subject} was successfully added:rel=#{relation}:#{link_[:msg]}"
              flash[:notice] += t(:ctrl_object_added,:object=>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>link_[:msg])
            else
              #flash[:notice] += "<br> forum #{@forum.subject} was not added:rel=#{relation}:#{link_[:msg]}"
              flash[:notice] += t(:ctrl_object_not_added,:object=>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>link_[:msg])
              @forum.destroy
              error=true
            end
          else
            #flash[:notice] += "<br> link #{@forum.subject} was not created:rel=#{relation}:#{link_[:msg]}"
            flash[:notice] += t(:ctrl_object_not_linked,:object=>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>nil)
            @forum.destroy
            error=true
          end
        else
          flash[:notice] += t(:ctrl_object_not_created, :object=>t(:ctrl_forum_item))
          @forum.destroy
          error=true
        end
      else
        #flash[:notice] += "<br> forum #{@forum.subject} was not saved:rel=#{relation}:#{link_[:msg]}"
        flash[:notice] += t(:ctrl_object_not_saved,:object=>t(:ctrl_forum),:ident=>@forum.subject,:relation=>relation,:msg=>link_[:msg])
        error=true
      end
      if error==false
        format.html { redirect_to(@part) }
      else
        puts 'PartController.add_forum:part_id='+@part.id.to_s
        @types=Typesobject.find_for("forum")
        @status= Statusobject.find_for("forum")
        format.html { render  :action => :new_forum, :id => @part.id   }
      end
      format.xml  { head :ok }
    end
  end

  def promote
    @part = Part.find(params[:id])
    ctrl_promote(@part)
  end

  def demote
    @part = Part.find(params[:id])
    ctrl_demote(@part)
  end

  def add_part_to_favori
    part=Part.find(params[:id])
    @favori_part.add_part(part)
    ##redirect_to(:action => index)
  end

  def empty_favori_part
    session[:favori_part]=nil
    @favori_part=nil
    #flash[:notice] ="Plus de favoris part"
    ##redirect_to :action => :index
  end

end
