#
# A group of users
#
class Group < ActiveRecord::Base
  include Models::SylrplmCommon

  has_many :user_groups, :dependent => :delete_all
  has_many :users, :through => :user_groups

  has_many :group_definitions, :dependent => :delete_all
  has_many :definitions, :through => :group_definitions

  has_many :groups, :class_name => "Group", :foreign_key => "father_id"

  belongs_to :father, :class_name => "Group"

  #
  # User and Group share this method, which returns login and name respectively
  #
  def ident; name; end
  def system_name; name; end
  def designation; name; end

  def typesobject
    Typesobject.find_by_forobject(model_name)
  end

  def father_name
    father.try(:name) || ''
  end

  def may_launch_untracked_process?
    self.definitions.detect { |d| d.name == '*untracked*' }
  end

  def may_launch_embedded_process?
    self.definitions.detect { |d| d.name == '*embedded*' }
  end

  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret = {}
    unless filter.nil?
      ret[:qry]    = "name LIKE :v_filter "
      ret[:values] = { v_filter: filter }
    end
    ret
  end

  def others
    Group.all
  end

end
