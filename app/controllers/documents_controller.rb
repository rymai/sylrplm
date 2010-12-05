#require 'lib/controllers/plm_object_controller_module'
#require 'lib/controllers/plm_init_controller_module'
class DocumentsController < ApplicationController
  include Controllers::PlmObjectControllerModule
  include Controllers::PlmInitControllerModule
  before_filter :check_init, :only=>[:new]
  
  #droits d'acces suivant le controller et l'action demandee
  #administration par le menu Access
  #access_control (Document.controller_access())
  access_control (Access.find_for_controller(controller_class_name()))
  
  # GET /documents
  # GET /documents.xml
  def index
    @documents = Document.find_paginate({:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])}) 
    respond_to do |format|
      #flash[:notice] =Document.controller_access()
      #flash[:notice] = "Filter=#{params[:query]} "
      format.html # index.html.erb
      format.xml  { render :xml => @documents[:recordset]  }
    end
  end
  
  # GET /documents/1
  # GET /documents/1.xml
  def show
    @document = Document.find(params[:id])
    @datafiles=@document.get_datafiles
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @document }
    end
  end
  
  # GET /documents/new
  # GET /documents/new.xml
  def new
    @document = Document.create_new(nil, @user)
    @types=Document.get_types_document
    @volumes = Volume.find_all 
    @status= Statusobject.find_for("document")
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @document }
    end
  end
  
  # GET /documents/1/edit
  def edit
    @document = Document.find_edit(params[:id])
    @types=Typesobject.find_for("document")
    @volumes = Volume.find_all 
    @status= Statusobject.find_for("document")
    #@status= Statusobject.find_for("document")
    puts "document.edit:type="+@document.statusobject.inspect
  end
  
  # POST /documents
  # POST /documents.xml
  def create
    document=params[:document]
    #    uploaded_file=document[:uploaded_file]
    #contournement pour faire le upload apres la creation pour avoir la revision dans
    #get_repository !!!!!!!!!!!!!!
    #document.delete(:uploaded_file)
    @document = Document.create_new(document,@user)
    @types=Document.get_types_document
    @volumes = Volume.find_all 
    respond_to do |format|
      if @document.save
        #@document.update_attributes(:uploaded_file=>uploaded_file)
        flash[:notice] = t(:ctrl_object_created,:object=>t(:ctrl_document),:ident=>@document.ident)
        format.html { redirect_to(@document) }
        format.xml  { render :xml => @document, :status => :created, :location => @document }
      else
        flash[:notice] = t(:ctrl_object_not_created,:object=>t(:ctrl_document))
        format.html { render :action => "new" }
        format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /documents/1
  # PUT /documents/1.xml
  def update
    @document = Document.find(params[:id])
    @volumes = Volume.find_all 
    @types=Typesobject.find_for("document")
    @status= Statusobject.find_for("document")
    respond_to do |format|
      if @document.update_attributes(params[:document])
        flash[:notice] = t(:ctrl_object_updated,:object=>t(:ctrl_document),:ident=>@document.ident)
        format.html { redirect_to(@document) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_updated,:object=>t(:ctrl_document),:ident=>@document.ident)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /documents/1
  # DELETE /documents/1.xml
  def destroy
    @document= Document.find(params[:id])
    if(@document!=nil)
      @document.destroy
      flash[:notice] = t(:ctrl_object_deleted,:object=>t(:ctrl_document),:ident=>@document.ident)
    else
      flash[:notice] = t(:ctrl_object_not_deleted,:object=>t(:ctrl_document),:ident=>@document.ident)
    end
    respond_to do |format|
      format.html { redirect_to(documents_url) }
      format.xml  { head :ok }
    end
  end
  
  def promote
    @document = Document.find(params[:id])
    @volumes = Volume.find_all 
    @types=Typesobject.find_for("document")
    @status= Statusobject.find_for("document")
    ctrl_promote(@document)
  end
  
  def demote
    @document = Document.find(params[:id])
    @volumes = Volume.find_all 
    @types=Typesobject.find_for("document")
    @status= Statusobject.find_for("document")
    ctrl_demote(@document)
  end
  
  def revise
    define_variables
    document = Document.find(params[:id])
    previous_rev=document.revision
    @document=document.revise
    @types=Document.get_types_document
    respond_to do |format|
      if(@document != nil)
        if @document.save
          puts 'document.revision apres save='+@document.id.to_s+":"+@document.revision;
          flash[:notice] = t(:ctrl_object_revised,:object=>t(:ctrl_document),:ident=>@document.ident,:previous_rev=>previous_rev,:revision=>@document.revision)
          format.html { redirect_to(@document) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
        end
      else
        @document = Document.find(params[:id])
        flash[:notice] = t(:ctrl_object_not_revised,:object=>t(:ctrl_document),:ident=>@document.ident,:previous_rev=>previous_rev)
        format.html { redirect_to(@document) }
        format.xml  { head :ok }        
      end
    end
  end
  
  def check_out
    @document = Document.find(params[:id])
    check=Check.findCheckout("document", @document) 
    
    if(check==nil)
      if(params[:reason]!="")
        check=Check.create_new("document",@document,params, @user)
        if check.save       
          flash[:notice] = t(:ctrl_object_checkout,:object=>t(:ctrl_document),:ident=>@document.ident,:reason=>params[:reason])
        else
          flash[:notice] = t(:ctrl_object_notcheckout,:object=>t(:ctrl_document),:ident=>@document.ident)
        end    
      else
        flash[:notice] = t(:ctrl_object_give_reason)
      end
    else
      flash[:notice] = t(:ctrl_object_already_checkout,:object=>t(:ctrl_document),:ident=>@document.ident) 
    end
    respond_to do |format|
      format.xml  { head :ok }
      format.html { redirect_to(@document) }
    end
    
  end
  
  def check_in
    @document = Document.find(params[:id])
    check=Check.findCheckout("document", @document)
    respond_to do |format|
      if(params[:reason]!="")
          if(check!=nil)
            check.checkIn(params,@user)
            if check.save   
              @document.update_attributes(params[:document])
              flash[:notice] = t(:ctrl_object_checkin,:object=>t(:ctrl_document),:ident=>@document.ident)
            else
              flash[:notice] = t(:ctrl_object_not_checkin,:object=>t(:ctrl_document),:ident=>@document.ident)
              
            end
          else
            flash[:notice] = t(:ctrl_object_notyet_checkout,:object=>t(:ctrl_document),:ident=>@document.ident)
          end
      else
        flash[:notice] = t(:ctrl_object_give_reason)
      end
      format.xml  { head :ok }
      format.html { redirect_to(@document) }
    end 
  end
  
  def check_free
    @document = Document.find(params[:id])
    check=Check.findCheckout("document", @document)
    respond_to do |format|
      if(check!=nil)
        if(params[:reason]!="")
          check.checkFree(params,@user)
          if check.save   
            flash[:notice] = t(:ctrl_object_checkfree,:object=>t(:ctrl_document),:ident=>@document.ident)
          else
            flash[:notice] = t(:ctrl_object_not_checkfree,:object=>t(:ctrl_document),:ident=>@document.ident)
            
          end
        else
          flash[:notice] = t(:ctrl_object_give_reason)
        end
      else
        flash[:notice] = t(:ctrl_object_notyet_checkout,:object=>t(:ctrl_document),:ident=>@document.ident)
        
      end
      
      format.xml  { head :ok }
      format.html { redirect_to(@document) }
    end
  end 
  
  def add_document_to_favori 
    document=Document.find(params[:id])
    puts "main_controller.add_document_to_favori:"+document.inspect
    @favori_document.add_document(document)
    ##redirect_to(:action => index) 
  end
  
  def empty_favori_document
    session[:favori_document]=nil
    @favori_document=nil
    #flash[:notice] ="Plus de favoris document"
    ##redirect_to :action => :index   
  end
  
  def new_datafile
    @object = Document.find(params[:id])
    @types=Typesobject.find_for("datafile")
    puts 'DocumentsController.new_datafile:'+@object.inspect
    respond_to do |format|      
      flash[:notice] = ""
      @datafile=Datafile.create_new(nil,@user)
      format.html {render :action=>:new_datafile, :id=>@object.id }
      format.xml  { head :ok }
    end
  end 
  
  def add_datafile
    @object = Document.find(params[:id])
    ctrl_add_datafile(@object,"document")
  end
end
