class Typesobject < ActiveRecord::Base
  validates_presence_of :object, :name
  has_many :documents
  has_many :parts
  has_many :projects
  has_many :customers
  
  def self.getTypes(s_object)
    find(:all, :order=>"name",
      :conditions => ["object = '"+s_object.to_s+"'"])
  end
  
  def self.getTypesNames(s_object)
    ret=[]
    types=getTypes(s_object)
    types.each do |t| 
      ret<<t.name 
      end
      ret
  end
  
  def self.getObjectsWithType
  		ret=["document","part","project","customer","forum","datafile","relation_document","relation_part","relation_project"]
  		ret
  end
  
  def self.find_all
          find(:all, :order=>"object,name")
  end 
  def self.find_for(object)
      find(:all, :order=>"object,name", :conditions => ["object = '#{object}' "])
  end
   
end
