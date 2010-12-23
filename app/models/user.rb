#require 'digest/sha1'

class User < ActiveRecord::Base
  include Models::SylrplmCommon
  
  has_and_belongs_to_many :roles
  belongs_to :role
  belongs_to :volume
  has_many :documents, :foreign_key => "owner"
  
  validates_presence_of     :login
  validates_uniqueness_of   :login
  
  attr_accessor :password_confirmation
  validates_confirmation_of :password
  before_create :set_initial_attributes
  
  def self.create_new(params)
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
  
  def self.find_validers
    all(:select => "login, email",
          :order => :login,
          :conditions => "roles.title like 'valid%'",
          :joins => "inner join roles on users.role_id = roles.id")
  end
  
  def self.check_admin
    admin_user=find_by_name('admin')
    ya_admin=false
    if admin_user!=nil
      admin_role=Role.find_by_name('admin')
      if admin_role!=nil
        if admin_user.roles.index(admin_role)!=nil
          ya_admin=true
        else
          admin_user.roles<<admin_role
          admin_user.role=admin_role
          admin_user.save
        end
      else
        params={
        :title=>'admin',:description=>'role admin'
        }
        admin_role=Role.new(params)        
        admin_role.save
        admin_user.roles<<admin_role
        admin_user.role=admin_role
        admin_user.save
      end
    else
      params={
      :login=>'admin',
      :password=>'admin',
      :password_confirmation=>'admin'
      }
      admin_user=new(params)
      params={:title=>'admin',:description=>'role admin'}
      admin_role=Role.new(params)
      admin_role.save
      admin_user.roles<<admin_role
      admin_user.role=admin_role
      admin_user.save
      puts "User.check_admin:admin_user="+admin_user.inspect
    end
    if ya_admin==false
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
    ya_admin
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
end