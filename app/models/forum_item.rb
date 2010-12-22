class ForumItem < ActiveRecord::Base
  include Models::SylrplmCommon
  
  validates_presence_of :forum_id,:message
  
  belongs_to :author,
    :class_name => "User",
    :foreign_key => "owner_id"
  
  belongs_to :parent,
  :class_name => "ForumItem",
  :foreign_key => "parent_id"
  
  belongs_to :forum
  
  has_many :forum_item,
  :class_name => "ForumItem",
  :foreign_key => "parent_id"
  
  def self.create_new(forum, params)
    item=self.new 
    item.forum=forum
    item.message=params[:message]
    item.author=@user
    item
  end
  def self.get_conditions(filter)
    filter=filter.gsub("*","%")
    conditions = ["message LIKE ? or "+qry_owner_id+" or "+qry_parent+" or "+qry_forum,
      "#{filter}", "#{filter}", "#{filter}", "#{filter}"] unless filter.nil?
  end
end
