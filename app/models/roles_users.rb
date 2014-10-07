class RolesUsers < ActiveRecord::Base
  include Models::SylrplmCommon

  validates_uniqueness_of :role_id, :scope => :user_id

  belongs_to :role
  belongs_to :user

  def self.get_conditions(filter)
    nil
  end
  
  def before_save
  	self.domain = role.domain
  	self.domain = user.domain if self.domain.nil?
  end
  def ident
  	"#{self.role}.#{self.user}"	
  end
end
