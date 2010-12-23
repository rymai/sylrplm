class Statusobject < ActiveRecord::Base
  include Models::SylrplmCommon
  validates_presence_of :object, :name, :rank
  has_many :documents
  has_many :parts
  has_many :projects
  has_many :customers
  
  named_scope :order_default, :order=>"object,rank,name ASC"
  named_scope :order_desc, :order=>"object,rank,name DESC"
  named_scope :cond_object, lambda{|obj| {:conditions=> ["object = ?",obj] }}
  named_scope :find_all , order_default.all
  
  def self.getObjectsWithStatus
    ret=["document","part","project","customer","forum"]
  end
  
  def self.find_for(object)
    order_default.find_all_by_object(object)
  end
  #  
  def self.get_first(object)
    #order_desc.find(:first, :order=>"object,rank ASC",  :conditions => ["object = '#{object}'"])
    order_default.find_by_object(object)
  end
  
  def self.get_last(object)
    #find(:first, :order=>"object,rank DESC",  :conditions => ["object = '#{object}'"])
    #order_default.cond_object(object).last
    order_default.find_last_by_object(object)
  end
  
  def self.find_next(object, current_status)
    if(current_status.rank<get_last(object).rank)
      new_rank=current_status.rank+1
      find(:first, :conditions => ["object = '#{object}' && rank=#{new_rank}"])
    else
      current_status
    end
  end
  
  def self.find_previous(object, current_status)
    if(current_status.rank>get_first(object).rank)
      new_rank=current_status.rank-1
      find(:first, :conditions => ["object = '#{object}' && rank=#{new_rank}"])
    else
      current_status
    end
  end
  
  def self.get_conditions(filter)
    filter=filter.gsub("*","%")
    conditions = ["object LIKE ? or name LIKE ? or description LIKE ? or rank LIKE ? or promote LIKE ? or demote LIKE ? ",
      filter, filter, filter, filter, filter, filter] unless filter.nil?
  end
end
