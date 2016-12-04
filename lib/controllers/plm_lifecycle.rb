require 'plm_mailer'
def ctrl_revise(object)
	previous_rev = object.revision
	@object = object.revise
	@types = Typesobject.get_types(object.class.name.downcase!)
	respond_to do |format|
		unless @object.nil?
			flash[:notice] = t(:ctrl_object_revised,:typeobj =>t(:ctrl_.to_s+@object.class.name.downcase!),:ident=>@object.ident,:previous_rev=>previous_rev,:revision=>@object.revision)
			format.html { redirect_to(@object) }
			format.xml  { head :ok }
		else
			@object = object
			flash[:notice] = t(:ctrl_object_not_revised,:typeobj =>t(:ctrl_.to_s+@object.class.name.downcase!),:ident=>@object.ident,:previous_rev=>previous_rev)
			format.html { redirect_to(@object) }
			format.xml  { head :ok }
		end
	end
end

def commit_promote?
	fname= "#{self.class.name}.#{__method__}"
	ret = [t("promote_by_select"),t("promote_by_menu"),t("promote_by_action")].include? params[:commit]
	#LOG.debug(fname){"commit=#{params[:commit]} ret=#{ret}"}
	ret
end

def commit_demote?
	fname= "#{self.class.name}.#{__method__}"
	ret = [t("demote_by_select"),t("demote_by_menu"),t("demote_by_action")].include? params[:commit]
	#LOG.debug(fname){"commit=#{params[:commit]} menu:#{t("demote_by_menu").force_encoding("UTF-8")} ret=#{ret}"}
	ret
end

def commit_revise?
	fname= "#{self.class.name}.#{__method__}"
	ret = [t("revise_by_menu"),t("revise_by_action")].include? params[:commit]
	ret
end

def ctrl_promote(a_object, withMail=true)
	fname= "#{self.class.name}.#{__method__}"
	#LOG.debug(fname){"params=#{params.inspect}"}
	email_ok=true
	if withMail==true
		email_ok=current_user.may_send_email?
	end
	respond_to do |format|
		if ctrl_update_lifecycle(a_object)
			msg = t(:ctrl_object_updated, :typeobj => t("ctrl_#{a_object.modelname}"), :ident => a_object.ident)
			if email_ok==true
				#LOG.debug(fname){"promote_by_action?=#{object.promote_by_action?}"}
				current_rank = a_object.statusobject.name
				if a_object.promote_by_action?
					st_from = a_object.statusobject.name
					unless a_object.next_status.nil?
					st_next = a_object.next_status.name
					end
					ctrl_create_process(format, "promotion", a_object, st_from, st_next)
					if flash[:error].blank?
						flash[:notice] = msg+ "<br/>"+t(:ctrl_object_promote_by_action,:typeobj =>t(:ctrl_.to_s+a_object.modelname),:ident=>a_object.ident,:current_rank=>current_rank,:new_rank=>nil,:validersMail=>nil)
						format.html { render :action => "show" }
###						format.html { redirect_to(a_object) }
						format.xml  { head :ok }
					else
						flash[:notice] = msg + "<br/>"+t(:ctrl_object_not_promote_by_action,:typeobj =>t(:ctrl_.to_s+a_object.modelname),:ident=>a_object.ident,:current_rank=>current_rank,:new_rank=>nil,:validersMail=>nil)
						format.html { render :action => "show" }
###						format.html { redirect_to(a_object) }
						format.xml  { render :xml => fei.errors, :status => :unprocessable_entity }
					end

				else
					a_object.next_status_id = params[a_object.modelname][:next_status_id]
					#LOG.debug(fname){"current_rank=#{current_rank} current_id=#{a_object.statusobject} next_status_id=#{a_object.next_status_id}"}
					a_object.promote
					new_rank = a_object.statusobject.name
					if a_object.save
						if withMail==true
							askUserMail=a_object.owner.email unless a_object.owner.nil?
							email=nil
							validers=[]#TODO pour test
							validersMail = ::PlmMailer.listUserMail(validers, current_user)
							email=PlmMailer.docValidated(a_object, current_user, @urlbase, askUserMail, validersMail)
						end
						flash[:notice] += "<br/>"+t(:ctrl_object_promoted,:typeobj =>t(:ctrl_.to_s+a_object.class.name.downcase!),:ident=>a_object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>nil)
						format.html { render :action => "edit_lifecycle" }
						format.xml  { head :ok }
					else
						flash[:error] = t(:ctrl_object_not_promoted,:typeobj =>t(:ctrl_.to_s+a_object.class.name.downcase!),:ident=>a_object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
						format.html { render :action => "edit_lifecycle" }
						format.xml  { render :xml => a_object.errors, :status => :unprocessable_entity }
					end
				end
			else
				flash[:notice] = t(:ctrl_user_no_email,:user=>current_user.login)
				format.html { render :action => "edit_lifecycle" }
				format.xml  { render :xml => a_object.errors, :status => :unprocessable_entity }
			end
		else
			flash[:error] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_document), :ident => @object_plm.ident, :error => @object_plm.errors.full_messages)
			format.html { render :action => "edit_lifecycle" }
			format.xml  { render :xml => a_object.errors, :status => :unprocessable_entity }
		end
	end
end

def ctrl_update_lifecycle(a_object)
	if a_object.update_attributes(params[a_object.modelname])
	ret=true
	else
	ret=false
	end
	ret
end

def ctrl_demote(a_object, withMail=true, st_from=nil, st_next=nil)
	fname= "#{self.class.name}.#{__method__}"
	#LOG.debug(fname){"params=#{params.inspect}"}
	email_ok=true
	if withMail==true
		email_ok=current_user.may_send_email?
	end
	respond_to do |format|
		ctrl_update_lifecycle(a_object)
		if email_ok==true
			#LOG.debug(fname){"promote_by_action?=#{object.promote_by_action?}"}
			if a_object.demote_by_action?
				st_from = a_object.statusobject.name
				unless a_object.next_status.nil?
				st_previous = a_object.previous_status.name
				end
				ctrl_create_process(format, "promotion", a_object, st_from, st_previous)
			else
				current_rank = a_object.statusobject.name
				a_object.previous_status_id = params[a_object.modelname][:previous_status_id]
				#LOG.debug(fname){"current_rank=#{current_rank} current_id=#{a_object.statusobject} next_status_id=#{a_object.next_status_id}"}
				a_object.demote
				new_rank = a_object.statusobject.name
				if a_object.save
					if withMail==true
						askUserMail=a_object.owner.email
						email=nil
						validers=[]#TODO pour test
						validersMail = PlmMailer.listUserMail(validers, current_user)
						email=PlmMailer.docValidated(a_object, current_user, @urlbase, askUserMail, validersMail)
						LOG.debug(fname){"email=#{email.inspect}"}
					end
					flash[:notice] = t(:ctrl_object_demoted,:typeobj =>t(:ctrl_.to_s+a_object.class.name.downcase!),:ident=>a_object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>nil)
					format.html { render :action => "edit_lifecycle" }
					format.xml  { head :ok }
				else
					flash[:notice] = t(:ctrl_object_not_demoted,:typeobj =>t(:ctrl_.to_s+a_object.class.name.downcase!),:ident=>a_object.ident,:current_rank=>current_rank,:new_rank=>new_rank,:validersMail=>validersMail)
					format.html { render :action => "edit_lifecycle" }
					format.xml  { render :xml => a_object.errors, :status => :unprocessable_entity }
				end
			end
		else
			flash[:notice] = t(:ctrl_user_no_email,:user=>current_user.login)
			format.html { render :action => "edit_lifecycle" }
			format.xml  { render :xml => a_object.errors, :status => :unprocessable_entity }
		end
	end
end



