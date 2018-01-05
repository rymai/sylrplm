class User < ActiveRecord::Base
	include Models::SylrplmCommon

	attr_accessor :designation, :password, :password_confirmation
	attr_accessor :link_attributes
	attr_accessor :session_domain

	attr_accessible :id
	attr_accessible :email
	attr_accessible :login
	attr_accessible :first_name
	attr_accessible :last_name
	attr_accessible :language
	attr_accessible :time_zone
	attr_accessible :theme
	attr_accessible :hashed_password
	attr_accessible :role_id
	attr_accessible :volume_id
	attr_accessible :nb_items
	attr_accessible :last_revision
	attr_accessible :check_automatic
	attr_accessible :show_mail
	attr_accessible :typesobject_id
	attr_accessible :group_id
	attr_accessible :project_id
	attr_accessible :domain
	attr_accessible :type_values
	attr_accessible :subscription_id

	#
	belongs_to :role
	belongs_to :group
	belongs_to :project
	belongs_to :volume
	belongs_to :typesobject
	belongs_to :subscription

	#has_many :user_groups, :dependent => :delete_all
	#has_many :groups, :through => :user_groups

	has_and_belongs_to_many :roles, :join_table=>:roles_users
	has_and_belongs_to_many :groups, :join_table=>:groups_users
	has_and_belongs_to_many :projects, :join_table=>:projects_users
	##TODO has_many :subscriptions, :foreign_key => :owner_id, :dependent => :delete_all

	validates_presence_of     :login, :first_name, :last_name , :typesobject
	#validates :email, :presence => true, :format => {:with => /^[^@\s]+)@((?:[-a-z0-9A-Z]+\.[a-zA-Z]{2,})$/}
	validates_uniqueness_of   :login
	validates_confirmation_of :password
	before_save :validity
	#
	def validity
		fname = "#{self.class.name}.#{__method__}:"
		#LOG.info(fname) {"user=#{self}"}
		valid = false
		begin
		#LOG.info(fname) {"email=#{self.email} : #{PlmServices.isEmail(self.email)}"}
			unless self.email.blank?
				if PlmServices.isEmail(self.email)
				valid=true
				else
					self.errors.add(:base,"User mail is not valid, example: me.name@free.fr")
				end
			else
				self.errors.add(:base,"User mail is mandatory, example: me.name@free.fr")
			end
		rescue Exception => e
			msg="Exception during user validity test:<br/>Exception=#{e}"
			self.errors.add(:base,msg)
		end
		#LOG.info(fname) {"errors=#{errors.inspect}"}
		valid
	end

	def name_translate
		login
	end

	def revisable?
		false
	end

	#
	# User and Group share this method, which returns login and name respectively
	#
	def ident; login; end

	def system_name; login; end

	def designation
		self.login+" "+self.first_name.to_s+" "+self.last_name.to_s
	end

	def password_confirmation=(val)
		@password_confirmation        = val
	end

	def initialize(*args)
		fname= "#{self.class.name}.#{__method__}"
		#LOG.info(fname) {"args=#{args.length}:#{args.inspect}"}
		#LOG.info(fname) {"errors? on user begin=#{self.errors.count}"}
		super
		self.language    = PlmServices.get_property(:LOCAL_DEFAULT)
		self.volume      = Volume.find_by_name(PlmServices.get_property(:VOLUME_NAME_DEFAULT))
		self.nb_items    = PlmServices.get_property(:NB_ITEMS_PER_PAGE).to_i
		self.theme       = PlmServices.get_property(:THEME_DEFAULT)
		self.typesobject = Typesobject.find_by_forobject_and_name("user", PlmServices.get_property(:TYPE_USER_DEFAULT))
		if args.size>0
			unless args[0][:user].nil?
				validate_user
			self.set_default_values_with_next_seq
			end
		end
		#LOG.info(fname) {"errors on user end=#{self.errors.count}"}
		self
	end

	def user=(auser)
		fname= "#{self.class.name}.#{__method__}"
	#LOG.info(fname) {"auser=#{auser}"}
	end

	def self.create_new(params=nil)
		raise Exception.new "Don't use this method!"
		unless params.nil?
			user = User.new(params)
		else
			user = User.new
			user.nb_items = PlmServices.get_property(:NB_ITEMS_PER_PAGE).to_i
			user.volume = Volume.find_by_name(PlmServices.get_property(:VOLUME_NAME_DEFAULT))
		user.set_default_values(1)
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
	#   - nil si le user ne peut etre cree
	# fonctionnement:
	#
	#
	def self.create_new_login(aparams, urlbase)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"params login=#{aparams}"}
		proj=Project.find_by_ident("PROJECT-admin")
		new_user=User.find_by_login(aparams["login"])
		new_user.destroy unless new_user.nil?
		params={}
		params["login"]    = aparams["login"]
		params["password"] = aparams["password"]
		params["email"]    = aparams["email"]
		params["first_name"]    = aparams["first_name"]
		params["last_name"]    = aparams["last_name"]
		params["password_confirmation"]    = aparams["password_confirmation"]
		new_user = User.new(params)
		if new_user.errors.nil? || new_user.errors.count==0
			if new_user.save
				LOG.debug(fname) {" new_user=#{new_user.inspect}"}
				LOG.debug(fname) {"urlbase=#{urlbase}"}
			else
				LOG.error(fname) {" user non sauve: errors= #{new_user.errors.inspect}"}
			end
		else
			LOG.error(fname) {" user non cree: errors= #{new_user.errors.inspect}"}
		end
		#else
=begin
puts fname+" manque des objets associes"
puts fname+" admin="+admin.inspect
puts fname+" group_consultants="+group_consultants.inspect
puts fname+" role_consultant="+role_consultant.inspect
puts fname+" proj="+proj.inspect
puts fname+" type user="+type.inspect
new_user=nil
=end

		#end
		new_user
	end

	def self.send_mail_new_login_to_admin(new_user,urlbase)
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {" new_user=#{new_user.inspect}"}
		LOG.debug(fname) {"urlbase=#{urlbase}"}
		admin = User.find_by_login(PlmServices.get_property(:USER_ADMIN))
		email = PlmMailer.new_login(new_user, admin, new_user, urlbase).deliver_now
		unless email.nil?
			msg = :ctrl_mail_created_and_delivered
			puts fname+" message cree et envoye pour #{new_user.login}"
		else
			puts fname+" message non cree pour #{new_user.login}"
			msg = :ctrl_mail_not_created
		end
		email
	end

	def validate_user_by_action?
		true
	end

	def validate_user
		fname= "#{self.class.name}.#{__method__}"
		#LOG.info(fname) {"attribute roles, groups and project to the user #{login}"}
		PlmServices.get_property(:ROLES_USER_DEFAULT).split(",").each do |elname|
		#LOG.info(fname) {"attribute role #{elname}"}
			el=::Role.find_by_title(elname)
			self.roles << el unless self.roles.include? el
		end
		PlmServices.get_property(:GROUPS_USER_DEFAULT).split(",").each do |elname|
		#LOG.info(fname) {"attribute group #{elname}"}
			el = ::Group.find_by_name(elname)
			self.groups << el unless self.groups.include? el
		end
		PlmServices.get_property(:PROJECTS_USER_DEFAULT).split(",").each do |elname|
		#LOG.info(fname) {"attribute project #{elname}"}
			el = ::Project.find_by_ident(elname)
			self.projects << el unless self.projects.include? el
		end
		self.typesobject=Typesobject.find_by_forobject_and_name("user", PlmServices.get_property(:TYPE_USER_VALIDATE))
		self
	end

	def role_translate
		PlmServices.translate("user_role_#{role}")
	end

	def group_translate
		PlmServices.translate("user_group_#{group}")
	end

	def project_translate
		PlmServices.translate("user_project_#{project}")
	end

	def self.find_by_name(name)
		#rails2 find(:first , :conditions => ["login = '#{name}' "])
		where("login = '#{name}' ").first
	end

	def modelname
		"user"
	end

	def to_s
		(self.login.presence || 'New user') +"/"+(self.role.nil? ? " " : self.role.title)+"/"+(self.group.nil? ? " " : self.group.name)+"/"
	end

	def validate
		self.errors.add(:base,"Missing password") if hashed_password.blank?
	end

	def self.authenticate(log, pwd)
		#puts __FILE__+".authenticate:"+log+":"+pwd
		user = self.find_by_login(log)
		if user
			if (user.salt.nil? || user.salt == "") && log==PlmServices.get_property(:USER_ADMIN)
				user.update_attributes({"salt" => "1234", "hashed_password" => encrypted_password(pwd, "1234")})
			end
			expected_password = encrypted_password(pwd, user.salt)
			if user.hashed_password != expected_password
				user = nil
			end
		end
		user
	end

	def reset_passwd
		self.password = "secret"
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
		###TODO origine , voir aussi lib/ruote.rb lookup_participant
		###[ system_name, 'unknown' ] + group_names
		[ system_name, 'unknown' ] + role_names
	end

	#
	# Returns the array of group names the user belongs to.
	#
	def group_names
		groups.collect { |g| g.name }
	end

	#
	# Returns the array of roles names the user belongs to.
	#
	def role_names
		roles.collect { |g| g.title }
	end

	#
	# Returns true if the username is "admin" or user is member of the administrators group
	#
	def is_admin?
		#puts "is_admin:"+login+" USER_ADMIN"+::SYLRPLM::USER_ADMIN+":"+login+" GROUP_ADMINS="+::SYLRPLM::GROUP_ADMINS+":"+group_names.to_s
		ret = login==PlmServices.get_property(:USER_ADMIN)
		ret = group_names.include?(PlmServices.get_property(:GROUP_ADMINS)) unless ret
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
		#puts "User.may_launch? #{definition} user.groups=#{self.groups}  def.groups=#{definition.groups}:#{(self.groups & definition.groups).size}"
		is_admin? or (self.roles & definition.roles).size > 0
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
		#rails2 ret=is_admin? || store_names.include?(workitem.store_name)
		ret=is_admin? || true
		#puts "User.may_see?: workitem=#{workitem.inspect}:#{ret}"
		ret
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
		ret=!self.role.nil? && !self.group.nil? && !self.project.nil?
		#puts "User.may_access?:#{ret}"
		ret
	end

	# peut se connecter
	def may_connect?
		ret=!self.typesobject.nil? && self.typesobject.name != PlmServices.get_property(:TYPE_USER_NEW_ACCOUNT) && !self.roles.empty? && !self.groups.empty? && !self.projects.empty?
		#puts "#{login} may_connect:type:#{typesobject.name} roles?:#{roles} group:#{groups} project:#{projects}:ret=#{ret}"
		ret
	end

	def can_edit?
		#TODO
		true
	end

	# verifie si le user a un contexte de connexion : role, group, projet deja defini
	def have_context?
		unless self.role.nil? || self.group.nil? || self.project.nil?
		ret=true
		end
		ret
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

	def tooltip
		#puts "user.tooltip"
		"#{first_name} #{last_name} (#{typesobject.ident})"
	end

	def self.encrypted_password(pwd, salt)
		#puts __FILE__+".encrypted_password:"+pwd.to_s+":"+salt.to_s
		string_to_hash = "#{pwd}wibble#{salt}"
		Digest::SHA1.hexdigest(string_to_hash)
	end

	def self.get_all
		fname= "#{self.class.name}.#{__method__}"
		ret=all.order("login ASC")
		ret
	end

	def self.find_with_mail
		#rails2 find(:all, :order => "login ASC", :conditions => 'email IS NOT NULL')
		self.all.order("login ASC").where("email IS NOT NULL")
	end

	#
	# user is it a valider ?
	#
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

	#
	# return all recent links stored for this user
	#
	def get_recent_links
		cond = "links.father_plmtype ='user' and links.father_id = #{self.id} and relations.name = '#{::SYLRPLM::RELATION_RECENT_ACTION}'"
		#rails2 links = ::Link.all(:all,		:conditions => cond,		:joins => "inner join relations on links.relation_id = relations.id",		:order => :updated_at)
		links = ::Link.all.where(cond).joins("inner join relations on links.relation_id = relations.id").order(:updated_at)

	end

	#
	# store a recent link
	# destroy old recent link(s) to limit the number
	#
	def manage_recents(object_plm, params)
		fname = "#{self.class.name}.#{__method__}:"
		begin
			max_recents = get_type_value("max_recents")
			max_recents = (max_recents.nil? ? ::SYLRPLM::MAX_RECENT_ACTION : max_recents.to_i)
			max_recents = ::SYLRPLM::MAX_RECENT_ACTION  if max_recents > ::SYLRPLM::MAX_RECENT_ACTION
			#LOG.info(fname) {"user=#{self} object_plm=#{object_plm} max_recents=#{max_recents}"}
			unless object_plm.nil?
				if relation_recent = Relation.find_by_name(::SYLRPLM::RELATION_RECENT_ACTION)
					link_recent = Link.new(father: self, child: object_plm, relation: relation_recent, user: self)
					link_recent.set_type_value("action", params[:action])
					recents = self.get_recent_links
					#LOG.debug(fname) {"recents=#{recents.count}"}
					if recents.count >= max_recents
						for i in 0..(recents.count - max_recents)
							recents[i].destroy
						end
					end
					if link_recent.save
						#LOG.info(fname) {"link saved=#{link_recent},relation=#{relation_recent}" }
						else
						LOG.warn(fname) {"link not saved=#{link_recent},relation=#{relation_recent}" }
					end
					recents = self.get_recent_links
					# traces
					if(1==0)
						LOG.debug(fname) {"recents=#{recents.count}"}
						recents.each do |recent|
							LOG.debug(fname) {"recent:#{recent} #{recent.updated_at}"}
						end
					end
				end
			end
		rescue Exception=>e
			LOG.debug(fname) {"ERREUR durant creation link recent #{e}"}
		end
		true
	end

	def self.get_conditions(filter)
		filter=filter.gsub("*","%")
		ret={}
		unless filter.nil?
			ret[:qry] = "login LIKE :v_filter or "+qry_role+" or email LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
			ret[:values]={:v_filter => filter}
		end
		ret
	end

	private

	def create_new_salt
		self.salt = self.object_id.to_s + rand.to_s
	end

# recherche du nom du user connecte

end
