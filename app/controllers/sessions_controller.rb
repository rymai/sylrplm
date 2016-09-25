class SessionsController < ApplicationController

	skip_before_filter :authorize, :check_user
def index

end
	def new
		puts "sessions_controller.new"+params.inspect
		puts "sessions_controller.new:flash="+flash[:notice] unless flash[:notice].nil?
		@current_users = User.find_paginate({:user=> current_user, :filter_types => params[:filter_types],:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
	#puts "sessions_controller.new @current_users=#{@current_users}"
	end

	def edit
		#puts "sessions_controller.edit"+params.inspect
	end

	# activation d'un nouveau compte
	# appelle depuis un mail envoye par PLMMailer.new_login
	def activate
		#puts "sessions_controller.activate"+params.inspect
		user = User.find(params[:id]) if User.exists?(params[:id])
		unless user.nil?
			if user.may_connect?
				type=Typesobject.find_by_forobject_and_name("user", PlmServices.get_property(:TYPE_USER_PERSON))
				user.typesobject=type
				if user.save
					@current_user = user
					session[:user_id] = user.id
					flash[:notice] = t(:ctrl_role_needed)
					respond_to do |format|
						format.html { render :action => :edit }
						format.xml { head :ok }
					end
				else
					flash[:notice] = t(:ctrl_new_account_not_validated, :user=>user.login)
					#puts "sessions_controller.activate new_account_not_validated :"+user.to_s
					respond_to do |format|
					#format.html { render :action => :new }
						format.html { redirect_to user}
						format.xml {render :xml => errs, :status => :unprocessable_entity }
					end
				end
			else
				flash[:error] = t(:ctrl_user_not_valid,:user=>user )
				@current_user=nil
				#puts "sessions_controller.activate user_not_valid :"+user.to_s
				respond_to do |format|
					format.html { redirect_to user }
					format.xml {render :xml => errs, :status => :unprocessable_entity }
				end
			end
		else
			flash[:notice] = t(:ctrl_new_account_not_existing, :user=>nil)
			respond_to do |format|
				format.html { render :action => :new }
				format.xml {render :xml => errs, :status => :unprocessable_entity }
			end
		end

	end

	def create
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"params=#{params}"}
		par=params[:session]
		#puts "sessions_controller.create"+params.inspect
		@current_users = User.find_paginate({:user=> current_user, :filter_types => params[:filter_types],:page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items=>get_nb_items(params[:nb_items])})
		commit=params["commit"]
		submit_account=t(:submit_account)
		#puts "sessions_controller.create:commit=#{commit} submit_account=#{submit_account}"
		if commit == submit_account
			#puts "sessions_controller.create:compte renseigne"
			# compte renseigne (new)
			cur_user = User.authenticate(par["login"], par["password"])
			unless cur_user.nil?
				#puts "sessions_controller.create:user reconnu, verif si il peut se connecter"
				# user reconnu, verif si il peut se connecter (role, groupe, projet, ...)
				flash[:notice] = check_user_connect(cur_user)
				if flash[:notice].nil?
					LOG.debug(fname) {"create: il peut se connecter"}
					@current_user = cur_user
					session[:user_id] = cur_user.id
					flash[:notice] = t(:ctrl_role_needed)
					respond_to do |format|
						if cur_user.have_context?
							# on se connecte sur ce contexte sans rien demander
							# le user devra aller dans outil/editer pour changer de contexte
							uri=session[:original_uri]
							session[:original_uri]=nil
							LOG.debug(fname) {"create: have_context => #{uri}" }
							format.html { redirect_to_main(uri) }
						else
							LOG.debug(fname) {"create: have_context=>edit pour le role/groupe/projet"}
							format.html { render :action => :edit }
						end
						format.xml { head :ok }
					end
				else
				LOG.debug(fname) {"create: il ne peut se connecter"}
					@current_user=nil
					session[:user_id] = nil
					respond_to do |format|
						format.html { render :new }
						format.xml {render :xml => errs, :status => :unprocessable_entity }
					end
				end
			else
			  LOG.debug(fname) {"create: login/mot de passe non reconnu=> nouvelle saisie"}
				@current_user=nil
				session[:user_id] = nil
				flash[:error] = t(:ctrl_invalid_login)
				respond_to do |format|
					format.html { render :new }
					format.xml {render :xml => errs, :status => :unprocessable_entity }
				end
			end

		elsif params[:commit] == t(:submit_new_account)
			#session[:login]=nil
			#session[:password]=nil
			LOG.debug(fname) {"create: demande de compte, on demande plus d'infos"}
			# demande de compte, on demande plus d'infos
			flash[:notice] = t(:ctrl_account_needed)
			respond_to do |format|
				format.html { render :action => :new_account_sessions }
				format.xml { head :ok }
			end
		end
	#puts "sessions_controller.create:fin"
	end

	def create_account
		fname= "#{self.class.name}.#{__method__}"
		#LOG.debug(fname) {"validation du compte, #{params.inspect}"}
		par = params[:session]
		# pour affichage dans la vue
		@current_users = User.find_paginate({:user=> current_user, :filter_types => params[:filter_types], :page=>params[:page],:query=>params[:query],:sort=>params[:sort], :nb_items => get_nb_items(params[:nb_items])})
		# validation du compte
		# nouvel utilisateur potentiel
		respond_to do |format|

		# if par["login"].empty? || par["password"].empty? || par["new_email"].empty? || par["language"].empty?
		# 	LOG.debug(fname) {"validation du compte ko"}
		# 	@current_user=nil
		# 	session[:user_id] = nil
		# 	flash[:error] =t(:ctrl_invalid_login)
		# 	format.html { render :new_account }
		# 	format.xml { render :xml => errs, :status => :unprocessable_entity }
		# else
		#LOG.debug(fname) {"validation du compte ok"}
		# tout est saisis: creation du nouveau compte
			cur_user = User.create_new_login(par, @urlbase)
			#LOG.debug(fname){"cur_user=#{cur_user.inspect} errors=#{cur_user.errors.inspect}"}
			if  cur_user.errors.nil? || cur_user.errors.count==0
				#LOG.debug(fname){"create_process"}
				current_toremove=false
				if @current_user.nil?
					@current_user = User.find_by_login(PlmServices.get_property(:USER_ADMIN))
				current_toremove=true
				end
				ctrl_create_process(format, "validate", cur_user, nil,  nil)
				flash[:notice] = check_user_connect(cur_user)
				if current_toremove
					@current_user =nil
				end
				if flash[:notice].nil?
					@current_user = cur_user
					session[:user_id] = cur_user.id
					flash[:notice] = t(:ctrl_role_needed)
					format.html { render :action => "edit" }
					format.xml { head :ok }
				else
				#LOG.debug(fname){"flash=#{flash[:notice]}"}
					session[:user_id] = @current_user.id unless @current_user.nil?
					#format.html { redirect_to_main(nil , "The validated process is active, Try to connect later from the mail you receive") }
					format.html { redirect_to_main(nil, "The validated process is active, Try to connect later from the mail you receive") }
					#LOG.debug(fname){"render to main, flash=#{flash[:notice]} new_sessions_url=#{new_sessions_url}"}
					format.xml {render :xml => errs, :status => :unprocessable_entity }
				end
			else
				flash[:error] = t(:ctrl_new_account_not_created, :user=>par["login"])
				@session=cur_user
				#LOG.debug(fname){"render new_account:session=#{session}"}
				format.html { render :new_account_sessions }
				format.xml {render :xml => errs, :status => :unprocessable_entity }
			end
		### TODO cur_user.destroy unless (cur_user.nil? && !cur_user.errors.nil? && cur_user.errors==0)
		#end
		end
	end

	def login
		puts "sessions_controller.login"+params.inspect
		par=params[:session]
		if params[:commit] == t(:submit_login)
			cur_user = User.find(params[:user_id])
			# user reconnu (vue edit) : prise en compte du role, groupe, projet
			unless cur_user.nil?
				@current_user = cur_user
				session[:user_id] = cur_user.id
				if @current_user.update_attributes(par)
					session[:user_id] = @current_user.id
					uri=session[:original_uri]
					session[:original_uri]=nil
					flash[:notice] = t(:ctrl_user_connected, :user => current_user.login)
					respond_to do |format|
						format.html { redirect_to_main(uri) }
						format.xml { head :ok }
					end
				else
					errs=@current_user.errors
					flash[:error] = t(:ctrl_user_not_connected, :user => @current_user.login, :msg =>errs.inspect)
					@current_user=nil
					session[:user_id] = nil
					respond_to do |format|
						format.html { render :new }
						format.xml { render :xml => errs, :status => :unprocessable_entity }
					end
				end
			else
				@current_user=nil
				session[:user_id] = nil
				respond_to do |format|
					format.html { render :new }
					format.xml {render :xml => errs, :status => :unprocessable_entity }
				end
			end
		end
	end

	def destroy
		#puts "sessions_controller.destroy:"+params.inspect
		session[:user_id] = nil
		flash[:notice] = t(:ctrl_user_disconnected, :user => current_user.login) if current_user != nil
		#bouclage
		#format.html { redirect_to_main(uri) }
		#format.xml { head :ok }
		redirect_to(:controller => "main", :action => "index")
	end

end