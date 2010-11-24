class VolumesController < ApplicationController
  access_control (Access.findForController(controller_class_name()))
  # GET /volumes
  # GET /volumes.xml
  def index
    @volumes = Volume.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @volumes }
    end
  end
  
  # GET /volumes/1
  # GET /volumes/1.xml
  def show
    @volume = Volume.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @volume }
    end
  end
  
  # GET /volumes/new
  # GET /volumes/new.xml
  def new
    @volume = Volume.createNew
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @volume }
    end
  end
  
  # GET /volumes/1/edit
  def edit
    @volume = Volume.find(params[:id])
  end
  
  # POST /volumes
  # POST /volumes.xml
  def create
    @volume = Volume.new(params[:volume])
    dir=@volume.createDir(nil)
    respond_to do |format|
      if(dir!=nil) 
        if @volume.save
          #flash[:notice] = "Volume #{@volume.name} was successfully created on #{dir}"
          flash[:notice] = t(:ctrl_object_created,:object=>t(:ctrl_volume),:ident=>@volume.name+":"+dir)
          format.html { redirect_to(@volume) }
          format.xml  { render :xml => @volume, :status => :created, :location => @volume }
        else
          flash[:notice] = t(:ctrl_object_not_created,:object=>t(:ctrl_volume),:ident=>@volume.name+":"+dir)
          format.html { render :action => "new" }
          format.xml  { render :xml => @volume.errors, :status => :unprocessable_entity }
        end
      else
        #flash[:notice] = "Volume #{@volume.name} was not created on #{@volume.directory}."
        flash[:notice] = t(:ctrl_object_not_created,:object=>t(:ctrl_volume),:ident=>@volume.name+":"+@volume.directory)
        format.html { render :action => "new" }
        format.xml  { render :xml => @volume.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /volumes/1
  # PUT /volumes/1.xml
  def update
    @volume = Volume.find(params[:id])
    respond_to do |format|        
      if @volume.update_attributes(params[:volume])
        dir=@volume.createDir(params[:olddir])
        if(dir!=nil)
          flash[:notice] = t(:ctrl_object_not_updated,:object=>t(:ctrl_volume),:ident=>@volume.name+":"+dir)
        else
          flash[:notice] = t(:ctrl_object_not_updated,:object=>t(:ctrl_volume),:ident=>@volume.name)
        end
        format.html { redirect_to(@volume) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_updated,:object=>t(:ctrl_volume),:ident=>@volume.name)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @volume.errors, :status => :unprocessable_entity }
      end       
    end 
  end
  
  # DELETE /volumes/1
  # DELETE /volumes/1.xml
  def destroy
    @volume = Volume.find(params[:id])
    dirsave=@volume.directory
    st=@volume.destroyVolume
    #puts "volumes_controller.destroy:st="+st.to_s
    if(st==nil) 
      flash[:notice] = t(:ctrl_object_deleted,:object=>t(:ctrl_volume),:ident=>@volume.name+":"+dirsave)
    else
      #flash[:notice] = "Volume #{@volume.name} was not deleted on #{dirsave}, files found: #{st.gsub("\n","<br/>")}."
      flash[:notice] = t(:ctrl_object_not_deleted,:object=>t(:ctrl_volume),:ident=>@volume.name+":"+dirsave)+":"+st.gsub("\n","<br/>")
    end
    respond_to do |format|
      format.html { redirect_to(volumes_url) }
      format.xml  { head :ok }
    end
  end
end
