class RolesUser < ActiveRecord::Base
  include Models::SylrplmCommon

  validates_uniqueness_of :role_id, :scope => :user_id

  belongs_to :role
  belongs_to :user

  def self.get_conditions(filter)
    nil
  end
end
