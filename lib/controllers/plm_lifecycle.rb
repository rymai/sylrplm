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
	LOG.debug (fname){"commit=#{params[:commit]} ret=#{ret}"}
	ret
end

def commit_demote?
	fname= "#{self.class.name}.#{__method__}"
	ret = [t("demote_by_select"),t("demote_by_menu"),t("demote_by_action")].include? params[:commit]
	LOG.debug (fname){"commit=#{params[:commit]} menu:#{t("demote_by_menu").force_encoding("UTF-8")} ret=#{ret}"}
	ret
end

def commit_revise?
	fname= "#{self.class.name}.#{__method__}"
	ret = [t("revise_by_menu"),t("revise_by_action")].include? params[:commit]
	ret
end

def ctrl_promote(a_object, withMail=true)
	fname= "#{self.class.name}.#{__method__}"
	#LOG.debug (fname){"params=#{params.inspect}"}
	email_ok=true
	if withMail==true
		email_ok=current_user.may_send_email?
	end
	respond_to do |format|
		if ctrl_update_lifecycle(a_object)
			flash[:notice] = t(:ctrl_object_updated, :typeobj => t("ctrl_#{a_object.model_name}"), :ident => a_object.ident)
			if email_ok==true
				#LOG.debug (fname){"promote_by_action?=#{object.promote_by_action?}"}
				if a_object.promote_by_action?
					st_from = a_object.statusobject.name
					unless a_object.next_status.nil?
					st_next = a_object.next_status.name
					end
					ctrl_create_process(format, "promotion", a_object, st_from, st_next)
				else
					current_rank = a_object.statusobject.name
					a_object.next_status_id = params[a_object.model_name][:next_status_id]
					#LOG.debug (fname){"current_rank=#{current_rank} current_id=#{a_object.statusobject} next_status_id=#{a_object.next_status_id}"}
					a_object.promote
					new_rank = a_object.statusobject.name
					if a_object.save
						if withMail==true
							askUserMail=a_object.owner.email
							email=nil
							#validers=User.find_validers
							#if a_object.could_validate?
							#	validersMail=PlmMailer.listUserMail(validers)
							#	email=PlmMailer.create_docToValidate(a_object, current_user, @urlbase, validersMail)
							#end
							validers=[]#TODO pour test
							validersMail = PlmMailer.listUserMail(validers, current_user)
							email=PlmMailer.create_docValidated(a_object, current_user, @urlbase, askUserMail, validersMail)
							if(email != nil)
								email.set_content_type("text/html")
								PlmMailer.deliver(email)
							end
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
			flash[:error] = t(:ctrl_object_not_updated, :typeobj => t(:ctrl_document), :ident => @document.ident)
			format.html { render :action => "edit_lifecycle" }
			format.xml  { render :xml => a_object.errors, :status => :unprocessable_entity }
		end
	end
end

def ctrl_update_lifecycle(a_object)
	if a_object.update_attributes(params[a_object.model_name])
	ret=true
	else
	ret=false
	end
	ret
end

def ctrl_demote(a_object, withMail=true, st_from=nil, st_next=nil)
	fname= "#{self.class.name}.#{__method__}"
	#LOG.debug (fname){"params=#{params.inspect}"}
	email_ok=true
	if withMail==true
		email_ok=current_user.may_send_email?
	end
	respond_to do |format|
		ctrl_update_lifecycle(a_object)
		if email_ok==true
			#LOG.debug (fname){"promote_by_action?=#{object.promote_by_action?}"}
			if a_object.demote_by_action?
				st_from = a_object.statusobject.name
				unless a_object.next_status.nil?
				st_previous = a_object.previous_status.name
				end
				ctrl_create_process(format, "promotion", a_object, st_from, st_previous)
			else
				current_rank = a_object.statusobject.name
				a_object.previous_status_id = params[a_object.model_name][:previous_status_id]
				#LOG.debug (fname){"current_rank=#{current_rank} current_id=#{a_object.statusobject} next_status_id=#{a_object.next_status_id}"}
				a_object.demote
				new_rank = a_object.statusobject.name
				if a_object.save
					if withMail==true
						askUserMail=a_object.owner.email
						email=nil
						#validers=User.find_validers
						#if a_object.could_validate?
						#	validersMail=PlmMailer.listUserMail(validers)
						#	email=PlmMailer.create_docToValidate(a_object, current_user, @urlbase, validersMail)
						#end
						validers=[]#TODO pour test
						validersMail = PlmMailer.listUserMail(validers, current_user)
						email=PlmMailer.create_docValidated(a_object, current_user, @urlbase, askUserMail, validersMail)
						if(email != nil)
							email.set_content_type("text/html")
							PlmMailer.deliver(email)
						end
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

def ctrl_create_process(format, process_name, a_object, value1, value2)
	fname= "#{self.class.name}.#{__method__}"
	# run the promote process
	begin
		@definition = Definition.get_by_process_name(process_name, a_object, value1, value2)
		params[:definition_id] = @definition.id
		li = parse_launchitem
		options = { :variables => { 'launcher' => @current_user.login } }

		fei = RuotePlugin.ruote_engine.launch(li, options)
		LOG.info (fname) {" fei("+fei.wfid+") launched options="+options.to_s}
		headers['Location'] = process_url(fei.wfid)
		nb=0
		workitem = nil
		while nb<5 and workitem.nil?
			puts fname+" boucle "+nb.to_s+":"+fei.wfid
			sleep 0.8
			nb+=1
			workitem = ::Ruote::Sylrplm::ArWorkitem.get_workitem(fei.wfid)
		end
		LOG.info (fname) {"workitem="+workitem.inspect}
		unless workitem.nil?
			flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_process), :ident => "#{workitem.id} #{fei.wfid}")
			add_object_to_workitem(a_object, workitem)
			format.html { redirect_to(a_object) }
			format.xml  { head :ok }
		else
			flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process), :msg => "workitem non trouve")
			format.html { redirect_to(a_object) }
			format.xml  { render :xml => fei.errors, :status => :unprocessable_entity }
		end
	rescue Exception => e
		LOG.error { "fei not launched error="+e.inspect}
		LOG.error {" fei not launched li="+li.inspect}
		LOG.error {" options="+options.inspect}
		e.backtrace.each {|x| LOG.error (fname){x}}
		flash[:error] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_process), :msg => "fei not launched error=#{e}")
		#format.html { redirect_to new_process_path(:definition_id => @definition.id)}
		#format.html { redirect_to ({:controller => :definitions , :action => :new_process, :definition_id => @definition.id}) }
		LOG.error (fname){"a_object=#{a_object}"}
		format.html { redirect_to(a_object) }
		format.xml  { render :xml => e, :status => :unprocessable_entity }

	end
end

def parse_launchitem
	fname= "#{self.class.name}.#{__method__}"
	ct                        = request.content_type.to_s
	# TODO : deal with Atom[Pub]
	# TODO : sec checks !!!
	begin
		return OpenWFE::Xml::launchitem_from_xml(request.body.read) \
		if ct.match(/xml$/)
		return OpenWFE::Json.launchitem_from_h(request.body.read) \
		if ct.match(/json$/)
	rescue Exception          => e
		raise ErrorReply.new(
      "#{e}:failed to parse launchitem from request body", 400)
	end
	# then we have a form...
	if definition_id = params[:definition_id]
		# is the user allowed to launch that process [definition] ?
		definition = Definition.find(definition_id)
		raise ErrorReply.new("you are not allowed to launch this process", 403
      ) unless @current_user.may_launch?(definition)
		params[:definition_url] = definition.local_uri if definition
	elsif definition_url = params[:definition_url]
		raise ErrorReply.new("not allowed to launch process definitions from adhoc URIs", 400
      ) unless @current_user.may_launch_from_adhoc_uri?
	elsif definition = params[:definition]
		# is the user allowed to launch embedded process definitions ?
		raise ErrorReply.new("not allowed to launch embedded process definitions", 400
      ) unless @current_user.may_launch_embedded_process?
	else
		raise ErrorReply.new("failed to parse launchitem from request parameters", 400)
	end
	if fields = params[:fields]
		params[:fields] = ActiveSupport::JSON::decode(fields)
	end
	ret = OpenWFE::LaunchItem.from_h(params)
	ret

end

def add_object_to_workitem(object, ar_workitem)
	fname = "plm_lifecycle."+__method__.to_s
	LOG.info (fname) {"#{object} #{ar_workitem}"}
	return ar_workitem.add_object(object)
end

