#require 'lib/models/plm_object'
class Project < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon
  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident
  
  belongs_to :customer
  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner,
    :class_name => "User",
    :foreign_key => "owner"
    
  has_many :links_documents,:class_name => "Link", :foreign_key => "father_id", :conditions => ["father_object='project' and child_object='document'"]
  has_many :documents , :through => :links_documents
  has_many :links_parts,:class_name => "Link", :foreign_key => "father_id", :conditions => ["father_object='project' and child_object='part'"]
  has_many :parts , :through => :links_parts
  has_many :links_customers,:class_name => "Link", :foreign_key => "child_id", :conditions => ["father_object='customer' and child_object='project'"]
  has_many :customers , :through => :links_customers
  
  def self.create_new(project, user)
    if(project!=nil)
      obj=Project.new(project)
    else
      obj=Project.new
      obj.set_default_values(true)
    end
    obj.owner=user
    obj.statusobject = Statusobject.get_first("project")
    puts obj.inspect
    obj
  end
  
  # modifie les attributs avant edition
  def self.find_edit(object_id)
    obj=find(object_id)
    obj.edit
    obj
  end
  
  def self.get_types_project 
    Typesobject.find(:all, :order=>"name",
          :conditions => ["object = 'project'"])
  end
  
  def add_parts_from_favori(favori)
    favori.items.each do |item|
      parts << item
    end    
  end
  
  def remove_parts()
    parts =nil  
  end
  
  def remove_part(item)
    parts.delete(item)
  end 
  
  def promote
    self.statusobject=Statusobject.find_next(:project,statusobject) 
    self   
  end
  
  def demote
    self.statusobject=Statusobject.find_previous(:project,statusobject) 
    self   
  end  
  def self.get_conditions(filter)
      filter=filter.gsub("*","%")
      conditions = ["ident LIKE ? or "+qry_type+" or designation LIKE ? or "+qry_status+
       " or "+qry_owner+" or date LIKE ? ",
       filter, filter, 
     filter, filter, 
     filter, filter ] unless filter.nil? 
  end
  
end
