class RolesUser < ActiveRecord::Base
  validates_uniqueness_of :user_id, :scope => :user_id
end
