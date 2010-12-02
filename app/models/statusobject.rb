class Statusobject < ActiveRecord::Base
  validates_presence_of :object, :name, :rank
  has_many :documents
  has_many :parts
  has_many :projects
  has_many :customers
  
  def self.getObjectsWithStatus
    ret=["document","part","project","customer","forum"]
  end
  
  def self.find_all
    find(:all, :order=>"object,rank,name")
  end
  
  def self.find_for(object)
    find(:all, :order=>"object,rank,name", :conditions => ["object = '#{object}' "])
  end
  
  def self.find_first(object)
    find(:first, :order=>"object,rank ASC",  :conditions => ["object = '#{object}'"])
  end
  
  def self.find_last(object)
    find(:first, :order=>"object,rank DESC",  :conditions => ["object = '#{object}'"])
  end
  
  def self.find_next(object, current_status)
    if(current_status.rank<find_last(object).rank)
      new_rank=current_status.rank+1
      find(:first, :conditions => ["object = '#{object}' && rank=#{new_rank}"])
    else
      current_status
    end
  end
  
  def self.find_previous(object, current_status)
    if(current_status.rank>find_first(object).rank)
      new_rank=current_status.rank-1
      find(:first, :conditions => ["object = '#{object}' && rank=#{new_rank}"])
    else
      current_status
    end
  end
  
end
