class Customer < ActiveRecord::Base
  include Models::SylrplmCommon
  include Models::PlmObject
  attr_accessor :link_attributes
  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident
  has_many :projects
  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner,
  :class_name => "User"
  belongs_to :group
  

  has_many :links_documents,:class_name => "Link", :foreign_key => "father_id", :conditions => ["father_plmtype='customer' and child_plmtype='document'"]
  has_many :documents , :through => :links_documents
  has_many :links_projects,:class_name => "Link", :foreign_key => "father_id", :conditions => ["father_plmtype='customer' and child_plmtype='project'"]
  has_many :projects , :through => :links_projects

  def self.create_new(customer,user)
    if(customer!=nil)
      obj=Customer.new(customer)
    else
      obj=Customer.new
      obj.set_default_values( true)
    end
    obj.owner=user
    obj.group=user.group
    obj.statusobject = Statusobject.get_first("customer")
    puts obj.inspect
    obj
  end

  def link_attributes=(att)
    @link_attributes = att
  end
  def link_attributes
    @link_attributes
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
