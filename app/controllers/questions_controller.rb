class QuestionsController < ApplicationController
  access_control (Access.find_for_controller(controller_class_name()))
  
  def index
    #@faqs = Faq.find :all
    @query="#{params[:query]}" 
    sort=params['sort']
    conditions = ["question LIKE ? or answer LIKE ? or updated_at LIKE ?",
    "#{params[:query]}%", "#{params[:query]}%", 
    "#{params[:query]}%" ] unless params[:query].nil?
    
    @faqs = Question.paginate(:page => params[:page], 
          :conditions => conditions,
    #:order => 'part_id ASC, ident ASC, revision ASC',
          :order => sort,
    :per_page => cfg_items_per_page)
    
  end
  
  def show
    @faq = Question.find params[:id]
  end
  
  def new
    @faq = Question.create_new
    respond_to do |format|
      #flash[:notice] = "#{@controllers.size()} controllers:1=#{@controllers[1].name}"
      format.html # new.html.erb
      format.xml  { render :xml => @faq }
    end
  end
  
  def create
    @faq = Question.new(params[:question])
    respond_to do |format|
      if @faq.save
        flash[:notice] = t(:ctrl_object_created,:object=>t(:ctrl_faq),:ident=>@faq.id)
        format.html { redirect_to(@faq) }
        format.xml  { render :xml => @faq, :status => :created, :location => @faq }
      else
        flash[:notice] =t(:ctrl_object_not_created,:object=>t(:ctrl_faq))
        format.html { render :action => :new }
        format.xml  { render :xml => @faq.errors, :status => :unprocessable_entity }
      end
    end
    
    
  end
  
  def edit
    @faq = Question.find(params[:id])
  end
  
  def update
    @faq = Question.find(params[:id])
    respond_to do |format|
      if @faq.update_attributes(params[:question])
        flash[:notice] = t(:ctrl_object_updated,:object=>t(:ctrl_faq),:ident=>@faq.id)
        format.html { redirect_to(@faq) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_notupdated,:object=>t(:ctrl_faq),:ident=>@faq.controller)
        format.html { render :action => :edit }
        format.xml  { render :xml => @faq.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @faq = Question.find params[:id]
    id=@faq.id
    @faq.destroy
    flash[:message] = flash[:notice] = t(:ctrl_object_deleted,:object=>t(:ctrl_faq),:ident=>id)
    respond_to do |format|
      format.html { redirect_to(faqs_url) }
      format.xml  { head :ok }
    end
  end
end
