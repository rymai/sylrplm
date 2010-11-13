#require "will_pagination"
require 'net/http'

class DocumentsController < ApplicationController
  include PlmObjectControllerModule
  include PlmInitControllerModule
  before_filter :check_init, :only=>[:new]
  
  #droits d'acces suivant le controller et l'action demandee
  #administration par le menu Access
  #access_control (Document.controller_access())
  access_control (Access.findForController(controller_class_name()))
 
  # GET /documents
  # GET /documents.xml
  def index
   
    #Document.getColumns().each do |col|
    #  puts 'DocumentsController.index:column='+col.to_s
    #end
    
    sort=params['sort']
    @query="#{params[:query]}" 
    if params[:part_id]
      @part = Part.find(params[:part_id])
      @documents = @part.documents.paginate(:page => params[:page], 
      :order => sort,
      :per_page => cfg_items_per_page)
      @total = @part.documents.count()
    else
      conditions = ["ident LIKE ? or "+qry_type+" or revision LIKE ? or designation LIKE ? or "+qry_status+
      " or "+qry_owner+" or date LIKE ? or "+qry_volume,
      "#{params[:query]}%", "#{params[:query]}%", 
    "#{params[:query]}%", "#{params[:query]}%", 
    "#{params[:query]}%", "#{params[:query]}%", 
    "#{params[:query]}%", "#{params[:query]}%" ] unless params[:query].nil?
      
      @total=Document.count( :conditions => conditions)
      @documents = Document.paginate(:page => params[:page], 
      :conditions => conditions,
      #:order => 'part_id ASC, ident ASC, revision ASC',
      :order => sort,
      :per_page => cfg_items_per_page)
    end
    respond_to do |format|
      #flash[:notice] =Document.controller_access()
      #flash[:notice] = "Filter=#{params[:query]} "
      format.html # index.html.erb
      format.xml  { render :xml => @documents }
    end
  end
  
  # GET /documents/1
  # GET /documents/1.xml
  def show
    @document = Document.find(params[:id])
    @first_status=Statusobject.find_first("document")
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @document }
    end
  end
  
  # GET /documents/new
  # GET /documents/new.xml
  def new
    @document = Document.createNew(nil, @user)
    @types=Document.getTypesDocument
    @volumes = Volume.find_all 
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
    #@document = @user.documents.build(params[:document])#
    puts "document_controller.create"
    document=params[:document]
    uploaded_file=document[:uploaded_file]
    #contournement pour faire le upload apres la creation pour avoir la revision dans
    #getRepository !!!!!!!!!!!!!!
    document.delete(:uploaded_file)
    @document = Document.createNew(document,@user)
    @types=Document.getTypesDocument
    @volumes = Volume.find_all 
    respond_to do |format|
      if @document.save
        @document.update_attributes(:uploaded_file=>uploaded_file)
        flash[:notice] = t(:ctrl_object_created,:object=>'Document',:ident=>@document.ident)
        format.html { redirect_to(@document) }
        format.xml  { render :xml => @document, :status => :created, :location => @document }
      else
        flash[:notice] = t(:ctrl_object_not_created,:object=>'Document')
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
        flash[:notice] = t(:ctrl_object_updated,:object=>'Document',:ident=>@document.ident)
        format.html { redirect_to(@document) }
        format.xml  { head :ok }
      else
       flash[:notice] = t(:ctrl_object_not_updated,:object=>'Document',:ident=>@document.ident)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /documents/1
  # DELETE /documents/1.xml
  def destroy
    doc = Document.find(params[:id])
    @document=doc.removeFile
    if(@document!=nil)
      @document.destroy
      flash[:notice] = t(:ctrl_object_deleted,:object=>'Document',:ident=>doc.ident)
    else
      flash[:notice] = t(:ctrl_object_not_deleted,:object=>'Document',:ident=>doc.ident)
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
  
  
  def show_file
    @document = Document.find(params[:id])
    send_data(@document.readFile,
        :filename=>@document.filename,
        :type=>@document.content_type,
        :disposition=>"inline")    
  end
  
  def download_file
    @document = Document.find(params[:id])
    send_data(@document.readFile,
      :filename=>@document.filename,
      :type=>@document.content_type,
      :disposition=>"attachment")   
    return @document.filename 
  end
  
  def show_file_data
    @document = Document.find(params[:id])
    send_data(@document.data,
      :filename=>@document.filename,
      :type=>@document.content_type,
      :disposition=>"inline")    
  end
  
  def revise
    define_variables
    document = Document.find(params[:id])
    previous_rev=document.revision
    @document=document.revise
    @types=Document.getTypesDocument
    respond_to do |format|
       if(@document != nil)
        if @document.save
          puts 'document.revision apres save='+@document.id.to_s+":"+@document.revision;
          flash[:notice] = t(:ctrl_object_revised,:object=>'Document',:ident=>@document.ident,:previous_rev=>previous_rev,:revision=>@document.revision)
          format.html { redirect_to(@document) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
        end
      else
        @document = Document.find(params[:id])
        flash[:notice] = t(:ctrl_object_not_revised,:object=>'Document',:ident=>@document.ident,:previous_rev=>previous_rev)
        #flash[:notice] = "Document cannot be revised from #{previous_rev} (not last revision or not frozen status ?)."
        format.html { redirect_to(@document) }
        format.xml  { head :ok }        
      end
    end
  end
  
  def check_out
    @document = Document.find(params[:id])
    check=Check.findCheckout("document", @document) 
    file=@document.filename
    if(check==nil)
      if(params[:reason]!="")
        check=Check.createNew("document",@document,params, @user)
        if check.save       
          flash[:notice] = t(:ctrl_object_checkout,:object=>'Document',:ident=>@document.ident,:file=>file,:reason=>params[:reason])
        else
          flash[:notice] = t(:ctrl_object_notcheckout,:object=>'Document',:ident=>@document.ident)
        end    
      else
        flash[:notice] = t(:ctrl_object_give_reason)
      end
    else
      flash[:notice] = t(:ctrl_object_already_checkout,:object=>'Document',:ident=>@document.ident,:file=>file) 
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
        if(params[:document] && params[:document][:uploaded_file]!=nil)
          if(check!=nil)
            check.checkIn(params,@user)
            if check.save   
              @document.update_attributes(params[:document])
              flash[:notice] = t(:ctrl_object_checkin,:object=>'Document',:ident=>@document.ident)
            else
               flash[:notice] = t(:ctrl_object_not_checkin,:object=>'Document',:ident=>@document.ident)
          
            end
          else
            flash[:notice] = t(:ctrl_object_notyet_checkout,:object=>'Document',:ident=>@document.ident)
          end
        else
          flash[:notice] = t(:ctrl_object_give_file)
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
              flash[:notice] = t(:ctrl_object_checkfree,:object=>'Document',:ident=>@document.ident)
           else
               flash[:notice] = t(:ctrl_object_not_checkfree,:object=>'Document',:ident=>@document.ident)
            
          end
        else
          flash[:notice] = t(:ctrl_object_give_reason)
        end
      else
            flash[:notice] = t(:ctrl_object_notyet_checkout,:object=>'Document',:ident=>@document.ident)

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
    return
  end
  
   def empty_favori_document
    session[:favori_document]=nil
    @favori_document=nil
    #flash[:notice] ="Plus de favoris document"
    ##redirect_to :action => :index   
  end
end
