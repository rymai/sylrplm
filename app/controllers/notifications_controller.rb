class NotificationsController < ApplicationController
	# GET /notifications
	# GET /notifications.xml
	before_filter :authorize, :except => nil
	def index
		fname="#{controller_name }.#{__method__}:"
		#LOG.info (fname) {"params=#{params.inspect}"}
		if params.include? :current_user
			#only notifications delivered to current user
			params[:query] = "#{current_user.login}"
		end
		@notifications = Notification.find_paginate({:user=> current_user, :filter_types => params[:filter_types], :page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
		#LOG.info (fname) {"notifs=#{@notifications.inspect}"}
		# if params.include? :current_user
		# @notifications[:recordset] = @notifications[:recordset].find_all {|notif| notif.responsible_id == current_user.id }
		# @notifications[:total] = @notifications[:recordset].count
		# LOG.info (fname) {"notifs=#{@notifications.inspect}"}
		# end
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @notifications[:recordset] }
		end
	end

	# GET /notifications/1
	# GET /notifications/1.xml
	def show
		show_
		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @notification }
		end
	end
	def show_
		@notification = Notification.find(params[:id])
	end

	# GET /notifications/new
	# GET /notifications/new.xml
	def new
		@notification = Notification.new(:user => current_user)
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
				flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_notification), :ident => @notification.ident)
				params[:id]=@notification.id
				show_
				format.html { render :action => "show" }
				format.xml  { render :xml => @notification, :status => :created, :location => @notification }
			else
				flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_notification), :msg => nil)
				format.html { render :action => "new" }
				format.xml  { render :xml => @notification.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /notifications/1
	# PUT /notifications/1.xml
	def update
		@notification = Notification.find(params[:id])
		@notification.update_accessor(current_user)
		@users=User.find(:all)
		respond_to do |format|
			if @notification.update_attributes(params[:notification])
				flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_notification), :ident => @notification.ident)
				show_
				format.html { render :action => "show" }
				format.xml  { head :ok }
			else
				flash[:error] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_notification), :ident => @notification.ident)
				format.html { render :action => "edit" }
				format.xml  { render :xml => @notification.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /notifications/1
	# DELETE /notifications/1.xml
	def destroy
		@notification = Notification.find(params[:id])
		if @notification.destroy
			flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_notification), :ident => @notification.ident)
		else
			flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_notification), :ident => @notification.ident)
		end
		respond_to do |format|
			format.html { redirect_to(notifications_url) }
			format.xml  { head :ok }
		end
	end

	def notify
		fname=self.class.name+"."+__method__.to_s+":"
		#puts fname+params[:id]+":"
		st = Notification.notify_all(params[:id])
		nb_users = 0
		nb_total = 0
		# message sur le nombre de notifs par user
		st.each do |cnt|
			nb_total += cnt[:count]
			nb_users += 1
		end
		#puts name+nb_users.to_s+"."+nb_total.to_s+":"+notifs
		flash[:notice] = t(:ctrl_notify, :nb_total => nb_total, :nb_users => nb_users)
		respond_to do |format|
			format.html { redirect_to(notifications_url) }
			format.xml  { head :ok }
		end
	end
end
