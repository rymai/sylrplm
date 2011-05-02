#require 'digest/sha1'

class User < ActiveRecord::Base
  include Models::SylrplmCommon

  has_and_belongs_to_many :roles
  belongs_to :role
  belongs_to :volume
  #has_many :documents, :foreign_key => "owner_id"
  has_many :user_groups, :dependent => :delete_all
  has_many :groups, :through => :user_groups

  validates_presence_of     :login
  validates_uniqueness_of   :login

  attr_accessor :password_confirmation
  validates_confirmation_of :password
  before_create :set_initial_attributes

  #
  # Used by is_admin?
  #
  ADMIN_GROUP_NAME = SYLRPLM::ADMIN_GROUP_NAME
  def self.create_new(params=nil)
    unless params.nil?
      user = User.new(params)
    else
      user = User.new
      user.set_default_values(true)
      user.nb_items = SYLRPLM::NB_ITEMS_PER_PAGE
      user.volume = Volume.find(1)
    end
    user
  end

  def self.find_by_name(name)
    find(:first , :conditions => ["login = '#{name}' "])
  end

  def validate
    errors.add_to_base("Missing password") if hashed_password.blank?
  end

  def self.authenticate(login, password)
    user = self.find_by_login(login)
    if user
      expected_password = encrypted_password(password, user.salt)
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

  def set_initial_attributes

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
  # Returns true if the user is member of the administrators group
  #
  def is_admin?

    group_names.include?(ADMIN_GROUP_NAME)
  end

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

  private

  def create_new_salt
    self.salt = self.object_id.to_s + rand.to_s
  end

  def self.encrypted_password(password, salt)
    string_to_hash = password + "wibble" + salt
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

  def self.check_admin
    admin_user=find_by_name('admin')
    if admin_user.nil?
      params={
        :login=>'admin',
        :password=>'admin',
        :password_confirmation=>'admin'
      }
      admin_user=new(params)
      puts "User.check_admin:admin_user="+admin_user.inspect
    end
    admin_role=Role.find_by_name('admin')
    unless admin_role.nil?
      if admin_user.roles.index(admin_role).nil?
        admin_user.roles<<admin_role
        admin_user.role=admin_role
      end
    else
      params={
        :title=>'admin',:description=>'role admin'
      }
      admin_role=Role.new(params)
      admin_role.save
      admin_user.roles<<admin_role
      admin_user.role=admin_role
    end
    admin_role=Role.find_by_name('valider')
    unless admin_role.nil?
      if admin_user.roles.index(admin_role).nil?
        admin_user.roles<<admin_role
        admin_user.role=admin_role
      end
    else
      params={
        :title=>'valider',:description=>'role valider'
      }
      admin_role=Role.new(params)
      admin_role.save
      admin_user.roles<<admin_role
      admin_user.role=admin_role
    end
    admin_user.save
    auser=find_by_name('designer')
    if auser.nil?
      #creation designer et consultant
      params={
        :login=>'designer',
        :password=>'designer',
        :password_confirmation=>'designer'
      }
      auser=new(params)
      params={:title=>'designer',:description=>'role designer'}
      arole=Role.new(params)
      arole.save
      auser.roles<<arole
      auser.role=arole
      auser.save
    end
    auser=find_by_name('consultant')
    if auser.nil?
      #
      params={
        :login=>'consultant',
        :password=>'consultant',
        :password_confirmation=>'consultant'
      }
      auser=new(params)
      params={:title=>'consultant',:description=>'role consultant'}
      arole=Role.new(params)
      arole.save
      auser.roles<<arole
      auser.role=arole
      auser.save
    end
    true
  end

  # recherche du theme
  def self.find_theme(session)
    ret=SYLRPLM::THEME_DEFAULT
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
        :user_not_connected
      end
    else
      :user_not_connected
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
        :user_unknown
      end
    else
      :user_not_connected
    end
  end

  # recherche du role du user connecte
  def self.find_userrole(session)
    if session[:user_id]
      if  user = User.find(session[:user_id])
        if(user.role != nil)
          user.role.title
        else
          ""
        end
      else
        ""
      end
    else
      ""
    end
  end

  # recherche du mail du user connecte
  def self.find_usermail(session)
    if session[:user_id]
      if  user = User.find(session[:user_id])
        if(user.email != nil)
          user.email
        else
          :user_unknown_mail
        end
      else
        :user_unknown_mail
      end
    else
      :user_unknown_mail
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