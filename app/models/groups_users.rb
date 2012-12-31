#
# Between users and groups
#
class GroupsUsers < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
  def self.get_conditions(filter)
    nil
  end
  def before_save
  	self.domain = user.domain
  	self.domain = group.domain if self.domain.nil?
  end
end

