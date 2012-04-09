class Forum < ActiveRecord::Base
  include Models::SylrplmCommon

  validates_presence_of :statusobject_id,:typesobject_id,:subject

  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner,
    :class_name => "User"
  belongs_to :group
  belongs_to :projowner,
    :class_name => "Project"

  has_many :forum_item,
  :conditions => ["parent_id is null"]
  def designation
    self.subject
  end
  
  def self.create_new(forum, user)
    if forum.nil?
      obj = Forum.new
      obj.statusobject = Statusobject.get_first("forum")
    obj.set_default_values(true)
    else
      obj = Forum.new(forum)
    end
    obj.owner = user
    obj.group = user.group
    obj.projowner=user.project
    obj
  end

  def ident
    self.subject
  end
  
  def find_root_items
    ForumItem.find(:all, :order=>"updated_at DESC",
    :conditions => ["forum_id = '#{self.id}' and parent_id is null"]
    )
  end

  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "subject LIKE :v_filter or " + qry_type + " or " + qry_owner_id + " or " + qry_status
      ret[:values]={:v_filter => filter}
    end
    ret
  #   "subject LIKE ? or " + qry_type + " or " + qry_owner_id + " or " + qry_status,
  end
end
