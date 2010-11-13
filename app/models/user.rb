require 'digest/sha1'

class User < ActiveRecord::Base
  
  has_and_belongs_to_many :roles
  belongs_to :role
  
  has_many :documents, :foreign_key => "owner"
  
  validates_presence_of     :login
  validates_uniqueness_of   :login
  
  attr_accessor :password_confirmation
  validates_confirmation_of :password
  
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
  
  def after_destroy
    if User.count.zero?
      raise "Can't delete last user"
    end
  end     
  
  private
  
  def create_new_salt
    self.salt = self.object_id.to_s + rand.to_s
  end
  
  def self.encrypted_password(password, salt)
    string_to_hash = password + "wibble" + salt
    Digest::SHA1.hexdigest(string_to_hash)
  end
  
  def self.find_validers
    ret=find(:all,
      :select => "us.login,us.email", 
      :order => "us.login", 
      :conditions => ["ro.title like ?",'valid%' ],
      :joins => "as us inner join roles as ro on us.role_id=ro.id")
      puts "User.find_validers:"+ret.inspect
      return ret
  end
  
  def isValider
    if(self.login.left=="valider")
      true
    else
      false
    end
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
    return ya_admin
  end
  
  
end