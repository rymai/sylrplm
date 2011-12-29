class User < ActiveRecord::Base
  include Models::SylrplmCommon

  attr_accessor :designation, :password, :password_confirmation
  attr_accessor :link_attributes
  #
  belongs_to :role
  belongs_to :group
  belongs_to :volume
  belongs_to :typesobject
  has_many :user_groups, :dependent => :delete_all
  has_and_belongs_to_many :roles
  has_many :groups, :through => :user_groups
  
  has_many :links_projects, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='project' and child_plmtype='user'"]
  #TODO ne renvoie rien => voir la fonction projects 
  #has_many :projects, :through => :links_projects
  
  belongs_to :project
  
  validates_presence_of     :login
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
  def link_attributes=(att)
    @link_attributes = att
  end
  def link_attributes
    @link_attributes
  end
  def designation
    self.login+" "+self.first_name.to_s+" "+self.last_name.to_s
  end
  def projects
    links_projects.collect { |p| p.father }
  end
  def designation=(val)
    designation        = val
  end
  
  def password_confirmation=(val)
    @password_confirmation        = val
  end
  
  def self.create_new(params=nil)
    unless params.nil?
      user = User.new(params)
    else
      user = User.new
      user.set_default_values(true)
      user.nb_items = ::SYLRPLM::NB_ITEMS_PER_PAGE
      user.volume = Volume.find(1)
    end
    user
  end

  def self.find_by_name(name)
    find(:first , :conditions => ["login = '#{name}' "])
  end

  def model_name
    "user"
  end
  def typesobject
    Typesobject.find_by_object(model_name)
  end
  def ident
    self.login+"/"+(self.role.nil? ? " " :self.role.title)+"/"+(self.group.nil? ? " " : self.group.name)
  end

  def validate
    errors.add_to_base("Missing password") if hashed_password.blank?
  end

  def self.authenticate(log, pwd)
    #puts __FILE__+".authenticate:"+log+":"+pwd
    user = self.find_by_login(log)
    if user
      if (user.salt.nil? || user.salt == "") && log==::SYLRPLM::ADMIN_USER_NAME
        user.update_attributes({"salt" => "1234", "hashed_password" => encrypted_password(pwd, "1234")})
      end
      expected_password = encrypted_password(pwd, user.salt)
      if user.hashed_password != expected_password
        user = nil
      end
    end
    user
  end

  # 'password' is a virtual attribute
  def password
    @password
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
    #puts "is_admin:"+login+" ADMIN_USER_NAME"+::SYLRPLM::ADMIN_USER_NAME+" ADMIN_GROUP_NAME="+ADMIN_GROUP_NAME
    ret = login==::SYLRPLM::ADMIN_USER_NAME
    if ret==false
      ret=group_names.include?(::SYLRPLM::ADMIN_GROUP_NAME) 
    end
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

  #  def self.check_admin
  #    true
  #  end

  #  def self.check_admin_old
  #    admin_user=find_by_name('admin')
  #    if admin_user.nil?
  #      params={
  #        :login=>'admin',
  #        :password=>'admin',
  #        :password_confirmation=>'admin'
  #      }
  #      admin_user=new(params)
  #      puts "User.check_admin:admin_user="+admin_user.inspect
  #    end
  #    admin_role=Role.find_by_name('admin')
  #    unless admin_role.nil?
  #      if admin_user.roles.index(admin_role).nil?
  #        admin_user.roles<<admin_role
  #        admin_user.role=admin_role
  #      end
  #    else
  #      params={
  #        :title=>'admin',:description=>'role admin'
  #      }
  #      admin_role=Role.new(params)
  #      admin_role.save
  #      admin_user.roles<<admin_role
  #      admin_user.role=admin_role
  #    end
  #    admin_role=Role.find_by_name('valider')
  #    unless admin_role.nil?
  #      if admin_user.roles.index(admin_role).nil?
  #        admin_user.roles<<admin_role
  #        admin_user.role=admin_role
  #      end
  #    else
  #      params={
  #        :title=>'valider',:description=>'role valider'
  #      }
  #      admin_role=Role.new(params)
  #      admin_role.save
  #      admin_user.roles<<admin_role
  #      admin_user.role=admin_role
  #    end
  #    admin_user.save
  #    auser=find_by_name('designer')
  #    if auser.nil?
  #      #creation designer et consultant
  #      params={
  #        :login=>'designer',
  #        :password=>'designer',
  #        :password_confirmation=>'designer'
  #      }
  #      auser=new(params)
  #      params={:title=>'designer',:description=>'role designer'}
  #      arole=Role.new(params)
  #      arole.save
  #      auser.roles<<arole
  #      auser.role=arole
  #      auser.save
  #    end
  #    auser=find_by_name('consultant')
  #    if auser.nil?
  #      #
  #      params={
  #        :login=>'consultant',
  #        :password=>'consultant',
  #        :password_confirmation=>'consultant'
  #      }
  #      auser=new(params)
  #      params={:title=>'consultant',:description=>'role consultant'}
  #      arole=Role.new(params)
  #      arole.save
  #      auser.roles<<arole
  #      auser.role=arole
  #      auser.save
  #    end
  #    true
  #  end

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
    ["login LIKE ? or "+qry_role+" or email LIKE ? ",
      filter, filter,
      filter ] unless filter.nil?
  end

  #
  # User and Group share this method, which returns login and name respectively
  #
  def system_name
    self.login
  end

end