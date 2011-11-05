class Typesobject < ActiveRecord::Base
  include Models::SylrplmCommon
  validates_presence_of :object, :name
  
  has_many :datafiles
  has_many :documents
  has_many :parts
  has_many :projects
  has_many :customers
  
  named_scope :order_default, :order=>"name ASC"
  named_scope :find_all , order_default.all

  def self.get_all
    order_default.find_all
  end
  
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
  		ret=["document", "part", "project", "customer", "forum", "project_typeaccess" "definition", "datafile", "relation", "user", "workitem", "ar_workitem", "syl_ar_workitem"].sort
  		ret
  end
  
  def self.find_for(object)
      #find(:all, :order=>"object,name", :conditions => ["object = '#{object}' "])
    order_default.find_all_by_object(object)
  end
  
  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "object LIKE :v_filter or name LIKE :v_filter or description LIKE :v_filter "
      ret[:values]={:v_filter => filter}
    end
    ret
      #conditions = ["object LIKE ? or name LIKE ? or description LIKE ? ",
  end
end
