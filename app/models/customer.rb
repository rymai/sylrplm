class Customer < ActiveRecord::Base
  include Models::SylrplmCommon
  include Models::PlmObject
  
  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident
  has_many :projects
  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner,
    :class_name => "User"
  has_many :links_documents,:class_name => "Link", :foreign_key => "father_id", :conditions => ["father_type='customer' and child_type='document'"]
  has_many :documents , :through => :links_documents
  has_many :links_projects,:class_name => "Link", :foreign_key => "father_id", :conditions => ["father_type='customer' and child_type='project'"]
  has_many :projects , :through => :links_projects
  
  def self.create_new(customer,user)
    if(customer!=nil)
      obj=Customer.new(customer)
    else
      obj=Customer.new
      obj.set_default_values( true)
    end
    obj.owner=user
    obj.statusobject = Statusobject.get_first("customer")
    puts obj.inspect
    obj
  end
  
  # modifie les attributs avant edition
  def self.find_edit(object_id)
    obj=find(object_id)
    obj.edit
    obj
  end
  
  def add_projects_from_favori(favori)
    favori.items.each do |item|
      projects << item
    end    
  end
  
  def remove_project(project)
    projects.delete( project)
  end  
  
  def add_documents_from_favori(favori)
    favori.items.each do |item|
      documents << item
    end    
  end
  
  
  # a valider si avant dernier status
  def is_to_validate
    if(self.statusobject!=nil && Statusobject.get_last(:customer)!=nil)
      if(self.statusobject.rank == Statusobject.get_last(:customer).rank-1)
        true
      else
        false
      end
    else
      false
    end 
  end
  def promote
    self.statusobject=Statusobject.find_next(:customer,statusobject) 
    self   
  end
  def demote
    self.statusobject=Statusobject.find_previous(:customer,statusobject) 
    self   
  end 
  
  def self.get_conditions(filter)
    filter=filter.gsub("*","%")
    ["ident LIKE ? or "+qry_type+" or designation LIKE ? or "+qry_status+
      " or "+qry_owner+" or date LIKE ? ",
      filter, filter, 
    filter, filter, 
    filter, filter ] unless filter.nil? 
  end
end
