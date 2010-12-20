class RolesUser < ActiveRecord::Base
  include Models::SylrplmCommon
  validates_uniqueness_of :user_id, :scope => :user_id
   def self.get_conditions(filter)
    nil
  end
end
