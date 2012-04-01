#
# Between users and project
#
class ProjectUser < ActiveRecord::Base
  include Models::SylrplmCommon

  validates_uniqueness_of :project_id, :scope => :user_id

  belongs_to :project
  belongs_to :user
  def self.get_conditions(filter)
    nil
  end
end

