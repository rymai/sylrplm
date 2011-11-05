class ForumItem < ActiveRecord::Base
  include Models::SylrplmCommon
  
  validates_presence_of :forum_id,:message
  
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
  
  def self.create_new(forum, params, user)
    obj=self.new 
    obj.forum=forum
    obj.message=params[:message]
    obj.author=user
    obj.group=user.group
    obj.projowner=user.project
    obj
  end
  def self.get_conditions(filter)
    
    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "message LIKE :v_filter or "+qry_owner_id+" or "+qry_parent+" or "+qry_forum
      ret[:values]={:v_filter => filter}
    end
    ret
      
    #conditions = ["message LIKE ? or "+qry_owner_id+" or "+qry_parent+" or "+qry_forum,
     
  end
end
