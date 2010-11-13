class Forum < ActiveRecord::Base

  validates_presence_of :statusobject_id,:typesobject_id,:subject
  
  
  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :creator,
    :class_name => "User",
    :foreign_key => "owner_id"
    
    
  has_many :forum_item,
  :conditions => ["parent_id is null"]
  
  def self.createNew(forum)
    
    if(forum==nil)
        forum=Forum.new  
        forum.statusobject=Statusobject.find_first("forum")
        Sequence.set_default_values(forum, self.name,true)
    else
        forum=Forum.new(forum)
        #Sequence.set_default_values(forum, self.name,false)
    end
    forum.creator=@user
    
    return forum
  end
  
  def findRootItems
    ForumItem.find(:all, :order=>"updated_at DESC",
            :conditions => ["forum_id = '#{self.id}' and parent_id is null"]
            )
  end
  
  def isFreeze
      if(self.statusobject!=nil && Statusobject.find_last("forum")!=nil)
          if(self.statusobject.rank == Statusobject.find_last("forum").rank)
            true
          else
            false
          end
      else
          false
      end
    end
    
end
