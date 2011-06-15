class Typesobject < ActiveRecord::Base
  include Models::SylrplmCommon
  validates_presence_of :object, :name
  
  has_many :datafiles
  has_many :documents
  has_many :parts
  has_many :projects
  has_many :customers
  
  named_scope :order_default, :order=>"object,name ASC"
  named_scope :find_all , order_default.all


  def self.get_types(s_object)
    find(:all, :order=>"name",
      :conditions => ["object = '"+s_object.to_s+"'"])
  end
  
  def self.get_types_names(s_object)
    ret=[]
    types=get_types(s_object)
    types.each do |t| 
      ret<<t.name 
      end
      ret
  end
  
  def self.get_objects_with_type
  		ret=["document","part","project","customer","forum","datafile","relation_document","relation_part","relation_project","relation_user"]
  		ret
  end
  
  def self.find_for(object)
      #find(:all, :order=>"object,name", :conditions => ["object = '#{object}' "])
    order_default.find_all_by_object(object)
  end
  
  def self.get_conditions(filter)
    filter=filter.gsub("*","%")
      conditions = ["object LIKE ? or name LIKE ? or description LIKE ? ",
      filter, filter, filter] unless filter.nil?
  end
end
