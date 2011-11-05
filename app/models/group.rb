#
# A group of users
#
class Group < ActiveRecord::Base
  include Models::SylrplmCommon
  
  has_many :user_groups, :dependent => :delete_all
  has_many :users, :through => :user_groups

  has_many :group_definitions, :dependent => :delete_all
  has_many :definitions, :through => :group_definitions

  belongs_to :father, :class_name => "Group"
  has_many :groups, :class_name => "Group", :foreign_key => "father_id"
  #
  # User and Group share this method, which returns login and name respectively
  #
  def system_name
    self.name
  end

  def ident
    self.name
  end

  def typesobject
    Typesobject.find_by_object(model_name)
  end

  def designation
    name #truncate(description, :length => 20)
  end

  def father_name
    (father ? father.name : "")
  end

  def may_launch_untracked_process?
    self.definitions.detect { |d| d.name == '*untracked*' }
  end

  def may_launch_embedded_process?
    self.definitions.detect { |d| d.name == '*embedded*' }
  end

  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "name LIKE :v_filter "
      ret[:values]={:v_filter => filter}
    end
    ret
  #conditions = ["name LIKE ? ", filter ] unless filter.nil?
  end

  def others
    Group.all
  end

end

