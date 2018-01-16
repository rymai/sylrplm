class ContactsController < ApplicationController
    include Controllers::PlmObjectController

    access_control(Access.find_for_controller(controller_name.classify))
    def index
        index_
        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @contacts }
        end
    end

    def show
        show_
        respond_to do |format|
            format.html # show.html.erb
            format.xml  { render :xml => @contact }
        end
    end

    def show_
        @contact = Contact.find(params[:id])
    end

    def new
        @contact  = Contact.new(user: current_user)
        @types  = Typesobject.get_types("contact")
        respond_to do |format|
            format.html # new.html.erb
            format.xml  { render :xml => @contact }
        end
    end

    def edit
        fname= "#{self.class.name}.#{__method__}"
        @contact  = Contact.find(params[:id])
        @types  = Typesobject.get_types("contact")
        LOG.debug(fname){"id=#{params[:id]}, contact=#{@contact}, types=#{@types}"}
    end

    def create
        fname= "#{self.class.name}.#{__method__}"
        LOG.debug(fname){"params=#{params.inspect}"}
        @contact  = Contact.new(params[:contact])
        @contact.update_attributes(params[:contact])
        LOG.debug(fname){"@contact=#{@contact.inspect}"}
        @types  = Typesobject.get_types("contact")
        respond_to do |format|
            if @contact.save
                sendContact
                flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_contact), :ident => @contact.ident)
                params[:id]=@contact.id
                show_
                format.html { render :action => "show" }
                format.xml  { render :xml => @contact, :status => :created, :location => @contact }
            else
                flash[:error] = t(:ctrl_object_not_created,:typeobj =>t(:ctrl_contact), :msg => nil)
                format.html { render :action => "new" }
                format.xml  { render :xml => @contact.errors, :status => :unprocessable_entity }
            end
        end
    end

    def update
        fname= "#{self.class.name}.#{__method__}"
        #LOG.debug(fname){"params=#{params.inspect}"}
        @contact = Contact.find(params[:id])
        respond_to do |format|
            if @contact.update_attributes(params[:contact])
                sendContact
                flash[:notice] = t(:ctrl_object_updated, :typeobj => t(:ctrl_contact), :ident => @contact.ident)
                show_
                format.html { render :action => "show" }
                format.xml  { head :ok }
            else
                flash[:error] = t(:ctrl_object_not_updated,:typeobj =>t(:ctrl_contact),:ident=>@contact.ident, :error => @contact.errors.full_messages)
                format.html { render :action => "edit" }
                format.xml  { render :xml => @contact.errors, :status => :unprocessable_entity }
            end
        end
    end

    #
    # update of edit panel after changing the type
    #
    def update_type
        fname= "#{self.class.name}.#{__method__}"
        #LOG.debug(fname){"params=#{params.inspect}"}
        @contact = Contact.find(params[:id])
        @types  = Typesobject.get_types("contact")
        ctrl_update_type @contact, params[:object_type]
    end

    def destroy
        @contact= Contact.find(params[:id])
        respond_to do |format|
            unless @contact.nil?
                if @contact.destroy
                    flash[:notice] = t(:ctrl_object_deleted, :typeobj => t(:ctrl_contact), :ident => @contact.ident)
                    format.html { redirect_to(contacts_url) }
                    format.xml  { head :ok }
                else
                    flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_contact), :ident => @contact.ident)
                    index_
                    format.html { render :action => "index" }
                    format.xml  { render :xml => @contact.errors, :status => :unprocessable_entity }
                end
            else
                flash[:error] = t(:ctrl_object_not_deleted, :typeobj => t(:ctrl_contact), :ident => @contact.ident)
            end
        end
    end

    :private

    def sendContact
        fname= "#{self.class.name}.#{__method__}"
        from=params[:contact][:email]
        body=params[:contact][:body]
        subject=params[:contact][:subject]
        admin=User.find_by_login(PlmServices.get_property(:USER_ADMIN))
        LOG.debug(fname){"contact from=#{from.inspect}"}
        LOG.debug(fname){"contact subject=#{subject}"}
        LOG.debug(fname){"contact body=#{body}"}
        email=PlmMailer.sendContact(from, admin,subject,body).deliver
        LOG.debug(fname){"contact email=#{email}"}
    end

    def index_
        @contacts = Contact.find_paginate({ :filter_types => params[:filter_types],:page => params[:page], :query => params[:query], :sort => params[:sort], :nb_items => get_nb_items(params[:nb_items]) })
        @object_plms=@contacts
    end
end
