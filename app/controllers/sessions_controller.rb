class SessionsController < ApplicationController

	skip_before_filter :authorize, :check_user
	def new
		#puts "sessions_controller.new"+params.inspect
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
			type=Typesobject.find_by_forobject_and_name("user", ::SYLRPLM::TYPE_USER_PERSON)
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
				flash[:notice] = t(:ctrl_new_account_not_created, :user=>user.login)
				respond_to do |format|
					format.html { render :action => :new }
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
		par=params[:session]
		#puts "sessions_controller.create"+params.inspect
		if params["commit"] == t(:submit_account)
			#puts "sessions_controller.create:compte renseigne"
			# compte renseigne (new)
			cur_user = User.authenticate(par["login"], par["password"])
			unless cur_user.nil?
				#puts "sessions_controller.create:user reconnu, verif si il peut se connecter"
				# user reconnu, verif si il peut se connecter (role, groupe, projet, ...)
				flash[:notice] = check_user_connect(cur_user)
				if flash[:notice].nil?
					#puts "sessions_controller.create:il peut se connecter"
					@current_user = cur_user
					session[:user_id] = cur_user.id
					flash[:notice] = t(:ctrl_role_needed)
					respond_to do |format|
						if cur_user.have_context?
							# on se connecte sur ce contexte sans rien demander
							# le user devra aller dans outil/editer pour changer de contexte
							uri=session[:original_uri]
							session[:original_uri]=nil
							format.html { redirect_to_main(uri) }
						else
							format.html { render :action => :edit }
						end
						format.xml { head :ok }
					end
				else
				#puts "sessions_controller.create:il ne peut se connecter"
					@current_user=nil
					session[:user_id] = nil
					respond_to do |format|
						format.html { render :new }
						format.xml {render :xml => errs, :status => :unprocessable_entity }
					end
				end
			else
			#puts "sessions_controller.create:user non reconnu"
				@current_user=nil
				session[:user_id] = nil
				flash[:error] = t(:ctrl_invalid_login)
				respond_to do |format|
					format.html { render :new }
					format.xml {render :xml => errs, :status => :unprocessable_entity }
				end
			end

		elsif params[:commit] == t(:submit_new_account)
			#puts "sessions_controller.create:demande de compte, on demande plus d'infos"
			# demande de compte, on demande plus d'infos
			flash[:notice] = t(:ctrl_account_needed)
			respond_to do |format|
				format.html { render :action => :new_account }
				format.xml { head :ok }
			end
		end
	#puts "sessions_controller.create:fin"
	end

	def create_account
		#puts "sessions_controller.create_new_account"+params.inspect
		#puts "create:validation du compte"
		par = params[:session]
		# validation du compte
		# nouvel utilisateur potentiel
		respond_to do |format|
			if par["login"].empty? || par["password"].empty? || par["new_email"].empty? || par["language"].empty?
				#puts "create:validation du compte ko"
				@current_user=nil
				session[:user_id] = nil
				flash[:error] =t(:ctrl_invalid_login)
				format.html { render :new }
				format.xml { render :xml => errs, :status => :unprocessable_entity }
			else
			#puts "create:validation du compte ok"
			# tout est saisis: creation du nouveau compte
				cur_user = User.create_new_login(par, @urlbase)
				puts "sessions_controller.create:cur_user="+cur_user.inspect
				unless cur_user.nil?
					flash[:notice] = check_user_connect(cur_user)
					if flash[:notice].nil?
						@current_user = cur_user
						session[:user_id] = cur_user.id
						flash[:notice] = t(:ctrl_role_needed)
						format.html { render :action => "edit" }
						format.xml { head :ok }
					else
						@current_user=nil
						session[:user_id] = nil
						format.html { render :new }
						format.xml {render :xml => errs, :status => :unprocessable_entity }
					end
				else
					flash[:error] = t(:ctrl_new_account_not_created, :user=>par["login"])
					format.html { render :new }
					format.xml {render :xml => errs, :status => :unprocessable_entity }
				end
			end
		end

	end

	def login
		#puts "sessions_controller.login"+params.inspect
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