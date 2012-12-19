class User < ActiveRecord::Base
	include Models::SylrplmCommon

	attr_accessor :designation, :password, :password_confirmation
	attr_accessor :link_attributes
	#
	belongs_to :role
	belongs_to :group
	belongs_to :project
	belongs_to :volume
	belongs_to :typesobject

	has_many :user_groups, :dependent => :delete_all
	has_many :groups, :through => :user_groups

	has_and_belongs_to_many :roles
	has_and_belongs_to_many :projects
	#has_many :projects_users, :dependent => :delete_all
	#has_many :projects, :through => :projects_users

	validates_presence_of     :login, :typesobject
	validates_uniqueness_of   :login

	validates_confirmation_of :password

	MAIL_NOTIFICATION_OPTIONS = [
		[0, :label_user_mail_option_all],
		[1, :label_user_mail_option_selected],
		[2, :label_user_mail_option_only_my_events],
		[3, :label_user_mail_option_only_assigned],
		[4, :label_user_mail_option_only_owner],
		[5, :label_user_mail_option_none]
	]

	#
	# User and Group share this method, which returns login and name respectively
	#
  def ident; login; end
  def system_name; login; end

	def designation
		self.login+" "+self.first_name.to_s+" "+self.last_name.to_s
	end

	def projects_obsolete
		ret = links_projects.collect {
		|p| p.father
		}
		puts "User.projects:user="+self.id.to_s+":"+self.designation+":"+ret.inspect
		ret
	end

	def password_confirmation=(val)
		@password_confirmation        = val
	end

	def self.create_new(params=nil)
		unless params.nil?
			user = User.new(params)
		else
			user = User.new
			user.nb_items = ::SYLRPLM::NB_ITEMS_PER_PAGE
			user.volume = Volume.find_by_name(::SYLRPLM::VOLUME_NAME_DEFAULT)
			user.set_default_values(true)
		end
		user
	end

	#
	# creation d'un nouveau compte sur demande depuis la fenetre de login par exemple
	# argums:
	#   - aparams: tablo contenant le login et le password et le new_email du compte a creer
	#   - urlbase: url de base de l'appli sylrplm
	# return:
	#   - le user cree avec les proprietes suivantes:
	#     * le type "#NEW_ACCOUNT" qui devra etre modifie pour que le user puisse se connecter
	#     * le volume par defaut , id=1
	#     * le groupe des consultants lui est affecté
	#     * le role consultant lui est affecté
	#     * un projet par defaut est cree pour lui: PROJET-login, ce projet lui est associé
	#     *
	#     *
	#     *
	#     *
	#     *

	#   - nil si le user ne peut etre cree
	# fonctionnement:
	#
	#
	def self.create_new_login(aparams, urlbase)
		name="User.create_new_login:"
		type=Typesobject.find_by_forobject_and_name(User.model_name, ::SYLRPLM::TYPE_USER_NEW_ACCOUNT)
		group_consultants=Group.find_by_name(::SYLRPLM::GROUP_CONSULTANTS)
		role_consultant=Role.find_by_title(::SYLRPLM::ROLE_CONSULTANT)
		admin = User.find_by_login(::SYLRPLM::USER_ADMIN)
		proj = Project.new(user: admin)
		type_proj=Typesobject.find_by_forobject_and_name(Project.model_name, ::SYLRPLM::TYPE_PROJ_ACCOUNT)
		typeacc_proj=Typesobject.find_by_forobject_and_name("project_typeaccess", ::SYLRPLM::TYPEACCESS_PUBLIC)
		unless group_consultants.nil? || role_consultant.nil? || proj.nil? || type.nil? || type_proj.nil? || typeacc_proj.nil?
			proj.ident=Project::for_user(aparams["login"])
			proj.typesobject=type_proj
			proj.typeaccess=typeacc_proj
			puts name+" proj="+proj.inspect
			if proj.save
				params={}
				params["typesobject_id"]=type.id
				params["volume_id"]=1
				#params["group_id"]=group_consultants.id
				#params["role_id"]=role_consultant.id
				#params["project_id"]=proj.id
				params["login"]=aparams["login"]
				params["password"]=aparams["password"]
				params["email"]=aparams["new_email"]
				new_user = User.new(params)
				if new_user.save
					new_user.groups<<group_consultants
					new_user.roles<<role_consultant
					puts name+" new_user="+new_user.inspect
					puts name+" rel="+proj.model_name+","+ new_user.model_name+","+ proj.typesobject.inspect+","+ new_user.typesobject.inspect

					if relation = Relation.by_types(proj.model_name, new_user.model_name, proj.typesobject.id, new_user.typesobject.id)
						link = Link.new(father: proj, child: new_user, relation: relation, useR: new_user)
						if link.save
							puts name+"urlbase="+urlbase

							if email = PlmMailer.create_new_login(new_user, new_user, new_user, urlbase)
								email.set_content_type("text/html")
								PlmMailer.deliver(email)
								msg = :ctrl_mail_created_and_delivered
								puts name+" message cree et envoye pour #{new_user.login}"
							else
								puts name+" message non cree pour #{new_user.login}"
								msg = :ctrl_mail_not_created
								new_user.destroy
								new_user=nil
							end
						else
							puts name+" lien non cree pour #{new_user.login}"
							new_user=nil
						end
					else
						puts name+" relation non trouvee pour #{new_user.login}"
						new_user=nil
					end
				else
					puts name+" user non sauve: #{new_user.login}"
					new_user=nil
				end
			else
				puts name+" projet "+proj.inspect+" non sauve"
				new_user=nil
			end
		else
			puts name+" manque des objets associes"
			puts name+"admin="+admin.inspect
			puts name+"group_consultants="+group_consultants.inspect
			puts name+"role_consultant="+role_consultant.inspect
			puts name+"proj="+proj.inspect
			puts name+"type user="+type.inspect
			puts name+"type_proj="+type_proj.inspect
			puts name+"typeacc_proj="+typeacc_proj.inspect
			new_user=nil
		end
		new_user
	end

	def self.find_by_name(name)
		find(:first , :conditions => ["login = '#{name}' "])
	end

	def model_name
		"user"
	end

	#def typesobject
	#  Typesobject.find_by_object(model_name)
	#end
	def to_s
		self.login+"/"+(self.role.nil? ? " " :self.role.title)+"/"+(self.group.nil? ? " " : self.group.name)+"/"
	end

	def validate
		errors.add_to_base("Missing password") if hashed_password.blank?
	end

	def self.authenticate(log, pwd)
		#puts __FILE__+".authenticate:"+log+":"+pwd
		user = self.find_by_login(log)
		if user
			if (user.salt.nil? || user.salt == "") && log==::SYLRPLM::USER_ADMIN
				user.update_attributes({"salt" => "1234", "hashed_password" => encrypted_password(pwd, "1234")})
			end
			expected_password = encrypted_password(pwd, user.salt)
			if user.hashed_password != expected_password
				user = nil
			end
		end
		user
	end

	def password=(pwd)
		#puts __FILE__+".password="+pwd
		@password = pwd
		return if pwd.blank?
		create_new_salt
		self.hashed_password = User.encrypted_password(self.password, self.salt)
	end

	def before_destroy
		if User.count.zero?
			raise "Can't delete last user"
		end
	end

	#
	# Returns the list of store names this user has access to
	#
	def store_names
		[ system_name, 'unknown' ] + group_names
	end

	#
	# Returns the array of group names the user belongs to.
	#
	def group_names
		groups.collect { |g| g.name }
	end

	#
	# Returns true if the username is "admin" or user is member of the administrators group
	#
	def is_admin?
		#puts "is_admin:"+login+" USER_ADMIN"+::SYLRPLM::USER_ADMIN+":"+login+" GROUP_ADMINS="+::SYLRPLM::GROUP_ADMINS+":"+group_names.to_s
		ret = login==::SYLRPLM::USER_ADMIN
		ret = group_names.include?(::SYLRPLM::GROUP_ADMINS) unless ret
		ret
	end

	#
	#
	# Returns true if the user is an administrator ('admin' group) or if the
	# user launched the given process instance
	#
	def is_launcher? (process)
		is_admin? or login == process.variables['launcher']
	end

	#
	# Returns true if user is in the admin group or the user may launch
	# a process instance of the given definition
	#
	def may_launch? (definition)
		return false if definition.is_special?
		is_admin? or (self.groups & definition.groups).size > 0
	end

	#
	# Preventing non-admin users from removing process definitions and
	# preventing admins from removing *embedded* and *untracked*
	#
	def may_remove? (definition)
		return false if definition.is_special?
		is_admin?
	end

	def may_launch_untracked_process?
		self.groups.detect { |g| g.may_launch_untracked_process? }
	end

	def may_launch_embedded_process?
		self.groups.detect { |g| g.may_launch_embedded_process? }
	end

	#
	# Returns true if the workitem is in a store the user has access to.
	# (always returns true for an admin).
	#
	def may_see? (workitem)
		is_admin? || store_names.include?(workitem.store_name)
	end

	#
	# Returns true if the user can send email
	#
	def may_send_email?
		ret = true
		askUserMail=self.email
		if askUserMail.blank?
			puts "User.may_send_email? :pas de mail"
		ret=false
		end
		ret
	end

	# peut creer des objets avec accessor
	def may_access?
		!self.role.nil? && !self.group.nil? && !self.project.nil?
	end

	# peut se connecter
	def may_connect?
		ret=!self.typesobject.nil? && self.typesobject.name != ::SYLRPLM::TYPE_USER_NEW_ACCOUNT && !self.roles.empty? && !self.groups.empty? && !self.projects.empty?
		puts "user.may_connect:type:"+ self.typesobject.name +
    ".role:"+ self.roles.empty?.to_s +
    ".group:" + self.groups.empty?.to_s +
    ".project:" + self.projects.empty?.to_s +
    ":"+ret.to_s
		ret
	end

	def self.notifications
		MAIL_NOTIFICATION_OPTIONS
	end

	def v_notification
		unless self.notification.nil?
			ret=User.notifications
		ret=ret[self.notification]
		end
		#puts "v_notification:"+self.notification.to_s+":"+User.notifications.inspect+":"+ret.to_s
		unless ret.nil?
		ret=ret[1]
		end
		I18n.t(ret) unless ret.nil?
	end

	#renvoie la liste des time zone tries sur le nom ([[texte,nom]])
	def self.time_zones
		ret=ActiveSupport::TimeZone.all.sort{|a,b| a.name <=> b.name}.collect {|z| [ z.to_s, z.name ]}
		#puts "time_zones:" + ret.inspect
		ret
	end

	#renvoie le texte du fuseau horaire en fonction du code
	def v_time_zone
		@time_zone ||= (self.time_zone.blank? ? nil : ActiveSupport::TimeZone[self.time_zone])
	end

	def get_default_view
		# cette vue standard doit exister
		View.find_by_name("standard")
	end

	private

	def create_new_salt
		self.salt = self.object_id.to_s + rand.to_s
	end

	def self.encrypted_password(pwd, salt)
		#puts __FILE__+".encrypted_password:"+pwd.to_s+":"+salt.to_s
		string_to_hash = pwd + "wibble" + salt
		Digest::SHA1.hexdigest(string_to_hash)
	end

	def self.find_all
		find(:all, :order=>"login ASC")
	end

	#user is it a valider ?
	def is_valider
		ret=false
		self.roles.each do  |role|
			if role.title.left(5)=='valid'
			ret=true
			end
			ret
		end
	#    all(:select => "login, email",
	#          :order => :login,
	#          :conditions => "roles.title like 'valid%'",
	#          :joins => "inner join roles on users.role_id = roles.id")
	end

	# recherche du theme
	def self.find_theme(session)
		ret = ::SYLRPLM::THEME_DEFAULT
		if session[:user_id]
			if user = User.find(session[:user_id])
				if(user.theme!=nil)
				ret=user.theme
				end
			end
		else
			if session[:theme]
				ret=session[:theme]
			end
		end
		ret
	end

	# recherche du user connecte
	def self.find_user(session)
		if session[:user_id]
			if  user = User.find(session[:user_id])
			user
			else
				nil
			end
		else
			nil
		end
	end

	def self.connected(session)
		!User.find_userid(session).nil?
	end

	# recherche de l'id du user connecte
	def self.find_userid(session)
		if session[:user_id]
			if  user = User.find(session[:user_id])
			user.id
			else
				nil
			end
		else
			nil
		end
	end

	# recherche du nom du user connecte
	def self.find_username(session)
		if session[:user_id]
			if user = User.find(session[:user_id])
			user.login
			else
				nil
			end
		else
			nil
		end
	end

	# recherche du role du user connecte
	def self.find_userrole(session)
		if session[:user_id]
			if  user = User.find(session[:user_id])
				if(user.role != nil)
				user.role.title
				else
					nil
				end
			else
				nil
			end
		else
			nil
		end
	end

	# recherche du mail du user connecte
	def self.find_usermail(session)
		if session[:user_id]
			if  user = User.find(session[:user_id])
				if(user.email != nil)
				user.email
				else
					nil
				end
			else
				nil
			end
		else
			nil
		end
	end

	def self.get_conditions(filter)
		filter=filter.gsub("*","%")
		ret={}
		unless filter.nil?
			ret[:qry] = "login LIKE :v_filter or "+qry_role+" or email LIKE :v_filter "
			ret[:values]={:v_filter => filter}
		end
		ret
	end

end
