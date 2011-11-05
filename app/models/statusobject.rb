class Statusobject < ActiveRecord::Base
  include Models::SylrplmCommon
  
  validates_presence_of :object, :name, :rank
  
  has_many :documents
  has_many :parts
  has_many :projects
  has_many :customers
  has_many :forums
  
  named_scope :order_default, :order=>"object,rank,name ASC"
  named_scope :order_desc, :order=>"object,rank,name DESC"
  named_scope :cond_object, lambda{|obj| {:conditions=> ["object = ?",obj] }}
  named_scope :find_all , order_default.all
  
  def self.get_objects_with_status
    ret=["document","part","project","customer","forum"]
  end
  
  def self.find_for(object, only_promote=false)
    Statusobject.order_default.find_all_by_object_and_promote(object,only_promote)
  end
  #  
  def self.get_first(object)
    #order_desc.find(:first, :order=>"object,rank ASC",  :conditions => ["object = '#{object}'"])
    Statusobject.find_by_object(object)
  end
  
  def self.get_last(object)
    #find(:first, :order=>"object,rank DESC",  :conditions => ["object = '#{object}'"])
    #order_default.cond_object(object).last
    order_default.find_last_by_object(object)
  end
  
  def get_previous
    if(rank > Statusobject.get_first(object).rank)
      new_rank=current_status.rank-1
      Statusobject.find(:first, :conditions => ["object = '#{object}' && rank=#{new_rank}"])
    else
      current_status
    end
  end
  
  def get_next
    if(rank < Statusobject.get_last(object).rank)
      new_rank = rank + 1
      Statusobject.find(:first, :conditions => ["object = '#{object}' && rank=#{new_rank}"])
    else
      self
    end
  end
  
  def self.find_next(object, current_status)
    if(current_status.rank < get_last(object).rank)
      new_rank=current_status.rank+1
      find(:first, :conditions => ["object = '#{object}' && rank=#{new_rank}"])
    else
      current_status
    end
  end
  
  def self.find_previous(object, current_status)
    if(rank > get_first(object).rank)
      new_rank = rank-1
      find(:first, :conditions => ["object = '#{object}' && rank=#{new_rank}"])
    else
      self
    end
  end
  
  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "object LIKE :v_filter or name LIKE :v_filter or description LIKE :v_filter or rank LIKE :v_filter or promote LIKE :v_filter or demote LIKE :v_filter "
      ret[:values]={:v_filter => filter}
    end
    ret
    #conditions = ["object LIKE ? or name LIKE ? or description LIKE ? or rank LIKE ? or promote LIKE ? or demote LIKE ? ",
  end
end
