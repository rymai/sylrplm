class Forum < ActiveRecord::Base
   include Models::SylrplmCommon
 
  validates_presence_of :statusobject_id,:typesobject_id,:subject
  
  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner,
    :class_name => "User"
  
  has_many :forum_item,
  :conditions => ["parent_id is null"]
  
  def self.create_new(forum)
    if(forum==nil)
      forum=Forum.new  
      forum.statusobject=Statusobject.get_first("forum")
      forum.set_default_values(true)
    else
      forum=Forum.new(forum)
    end
    forum.creator=@user
    forum
  end
  
  def find_root_items
    ForumItem.find(:all, :order=>"updated_at DESC",
            :conditions => ["forum_id = '#{self.id}' and parent_id is null"]
    )
  end
  
  def is_freeze
    if(self.statusobject!=nil && Statusobject.get_last("forum")!=nil)
      if(self.statusobject.rank == Statusobject.get_last("forum").rank)
        true
      else
        false
      end
    else
      false
    end
  end
   def self.get_conditions(filter)
    filter=filter.gsub("*","%")
      conditions = ["subject LIKE ? or "+qry_type+" or "+qry_owner_id+
      " or "+qry_status,
      filter, filter, 
    filter, filter] unless filter.nil?
  end
end
