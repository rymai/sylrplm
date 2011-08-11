class NotificationsController < ApplicationController
  # GET /notifications
  # GET /notifications.xml
  def index

    @notifications = Notification.find_paginate({ :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @notifications[:recordset] }
    end
  end

  # GET /notifications/1
  # GET /notifications/1.xml
  def show
    @notification = Notification.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @notification }
    end
  end

  # GET /notifications/new
  # GET /notifications/new.xml
  def new
    @notification = Notification.new
    @users=User.find(:all)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @notification }
    end
  end

  # GET /notifications/1/edit
  def edit
    @notification = Notification.find(params[:id])
    @users=User.find(:all)
  end

  # POST /notifications
  # POST /notifications.xml
  def create
    @notification = Notification.new(params[:notification])
    @users=User.find(:all)
    respond_to do |format|
      if @notification.save
        format.html { redirect_to(@notification, :notice => 'Notification was successfully created.') }
        format.xml  { render :xml => @notification, :status => :created, :location => @notification }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @notification.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /notifications/1
  # PUT /notifications/1.xml
  def update
    @notification = Notification.find(params[:id])
    @users=User.find(:all)
    respond_to do |format|
      if @notification.update_attributes(params[:notification])
        format.html { redirect_to(@notification, :notice => 'Notification was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @notification.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /notifications/1
  # DELETE /notifications/1.xml
  def destroy
    @notification = Notification.find(params[:id])
    @notification.destroy
    respond_to do |format|
      format.html { redirect_to(notifications_url) }
      format.xml  { head :ok }
    end
  end

  def notify
    name=self.class.name+"."+__method__.to_s+":"
    puts name+params[:id]+":"
    st=Notification.notify_all(params[:id])
    notifs=""
    nb_users=0
    nb_total=0
    st.each do |cnt|
      notifs+="<br/>"+cnt[:user].login+":"+cnt[:count].to_s+":"+t(cnt[:msg])
      nb_total+=cnt[:count]
      nb_users+=1
    end
    puts name+nb_users.to_s+"."+nb_total.to_s+":"+notifs
    flash[:notice] = t(:ctrl_notify, :nb_total => nb_total, :nb_users => nb_users, :notifications => notifs)
     respond_to do |format|
      format.html { redirect_to(notifications_url) }
      format.xml  { head :ok }
    end
  end
end
