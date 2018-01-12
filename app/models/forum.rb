# frozen_string_literal: true

class Forum < ActiveRecord::Base
  # pour def_user seulement
  include Models::PlmObject
  include Models::SylrplmCommon

  attr_accessor :user
  attr_accessible :owner_id, :typesobject_id, :statusobject_id, :next_status_id, :previous_status_id, :subject
  attr_accessible :description, :group_id, :projowner_id, :domain, :type_values

  validates_presence_of :statusobject_id, :typesobject_id, :subject

  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :next_status, class_name: 'Statusobject'
  belongs_to :previous_status, class_name: 'Statusobject'
  belongs_to :owner, class_name: 'User'
  belongs_to :group
  belongs_to :projowner, class_name: 'Project'

  # rails2 has_many :forum_items, :conditions => { parent_id: nil }
  has_many :forum_items, -> { where(parent_id: nil) }

  def user=(user)
    def_user(user)
  end

  def ident
    subject
  end

  def designation
    subject
  end

  def find_root_items
    ForumItem.all(order: 'updated_at DESC', conditions: ["forum_id = '#{id}' and parent_id is null"])
  end

  def self.get_conditions(filter)
    filter = filters.tr('*', '%')
    ret = {}
    unless filter.nil?
      ret[:qry] = "subject LIKE :v_filter or #{qry_type} or #{qry_owner_id} or #{qry_status} or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
      ret[:values] = { v_filter: filter }
    end
    ret
  end
end
