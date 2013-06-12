def ctrl_revise(model)
  object = model.find(params[:id])
  previous_rev = object.revision
  @object = object.revise
  @types = Typesobject.get_types(object.class.name.downcase!)
  respond_to do |format|
    if(@object != nil)
      if @object.save
        puts object.class.name+'.revision apres save='+@object.id.to_s+":"+@object.revision;
        flash[:notice] = t(:ctrl_object_revised,:typeobj =>t(:ctrl_.to_s+@object.class.name.downcase!),:ident=>@object.ident,:previous_rev=>previous_rev,:revision=>@object.revision)
        format.html { redirect_to(@object) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
      end
    else
      @object = model.find(params[:id])
      flash[:notice] = t(:ctrl_object_not_revised,:typeobj =>t(:ctrl_.to_s+@object.class.name.downcase!),:ident=>@object.ident,:previous_rev=>previous_rev)
      format.html { redirect_to(@object) }
      format.xml  { head :ok }
    end
  end
end

def ctrl_promote(object, withMail=true)
  email_ok=true
  if withMail==true
    email_ok=current_user.may_send_email?
  end
  respond_to do |format|
    if email_ok==true
      current_rank=object.statusobject.name
      object.promote
      new_rank=object.statusobject.name
      current_rank!=new_rank
      if object.save
        flash[:notice] = t(:ctrl_object_promoted,:typeobj =>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>nil)
        format.html { redirect_to(object) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_promoted,:typeobj =>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
        format.html { render :action => "edit" }
        format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
      end
    else
      flash[:notice] = t(:ctrl_user_no_email,:user=>current_user.login)
      format.html { render :action => "edit" }
      format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
    end
  end
end

def ctrl_demote(model, withMail=true)
  object = model.find(params[:id])
  current_rank=object.statusobject.name
  object.demote
  new_rank=object.statusobject.name
  respond_to do |format|
    if current_rank!=new_rank
      if object.save
        if withMail==true
          askUserMail=object.owner.email
          email=nil
          validers=User.find_validers
          if object.could_validate?
            validersMail=PlmMailer.listUserMail(validers)
            email=PlmMailer.create_docToValidate(object, current_user, @urlbase, validersMail)
          end
          if object.frozen?
            validersMail=PlmMailer.listUserMail(validers, current_user)
            email=PlmMailer.create_docValidated(object, current_user, @urlbase, askUserMail, validersMail)
          end
          if(email!=nil)
            email.set_content_type("text/html")
            PlmMailer.deliver(email)
          end
        end
        flash[:notice] = t(:ctrl_object_demoted,:typeobj =>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
        format.html { redirect_to(object) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_demoted,:typeobj =>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank)
        format.html { render :action => "edit" }
        format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
      end
    else
      flash[:notice] = t(:ctrl_object_not_demoted,:typeobj =>t(:ctrl_.to_s+object.class.name.downcase!),:ident=>object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
      format.html { redirect_to(object) }
      format.xml  { head :ok }
    end
  end
end

