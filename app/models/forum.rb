class Forum < ActiveRecord::Base
  #pour def_user seulement
  include Models::PlmObject
  include Models::SylrplmCommon

  attr_accessor :user

  validates_presence_of :statusobject_id, :typesobject_id, :subject

  belongs_to :typesobject
  belongs_to :statusobject
	belongs_to :next_status, :class_name => "Statusobject"
	belongs_to :previous_status, :class_name => "Statusobject"
  belongs_to :owner, :class_name => "User"
  belongs_to :group
  belongs_to :projowner, :class_name => "Project"

  has_many :forum_items, :conditions => { parent_id: nil }

  def user=(user)
		def_user(user)
	end

  def ident; subject; end
  def designation; subject; end

  def find_root_items
    ForumItem.all(order: "updated_at DESC", conditions: ["forum_id = '#{id}' and parent_id is null"])
  end

  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret = {}
    unless filter.nil?
      ret[:qry] = "subject LIKE :v_filter or #{qry_type} or #{qry_owner_id} or #{qry_status}"
      ret[:values] = { v_filter: filter }
    end
    ret
  end
end
