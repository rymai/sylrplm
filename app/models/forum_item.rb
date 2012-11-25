class ForumItem < ActiveRecord::Base
  include Models::SylrplmCommon

  attr_accessor :user

  validates_presence_of :forum_id, :message

  belongs_to :author,
    :class_name => "User",
    :foreign_key => "owner_id"
  belongs_to :group
  belongs_to :projowner,
    :class_name => "Project"

  belongs_to :parent,
  :class_name => "ForumItem",
  :foreign_key => "parent_id"

  belongs_to :forum

  has_many :forum_item,
  :class_name => "ForumItem",
  :foreign_key => "parent_id"

  def user=(user)
    self.author    = user
    self.group     = user.group
    self.projowner = user.project
  end

  def self.create_new(forum, params, user)
    raise Exception.new "Don't use this method!"
  end

  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret = {}
    unless filter.nil?
      ret[:qry]    = "message LIKE :v_filter or #{qry_type} or #{qry_owner_id} or #{qry_status}"
      ret[:values] = { v_filter: filter }
    end
    ret
  end
end
