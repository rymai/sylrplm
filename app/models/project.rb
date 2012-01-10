#require 'lib/models/plm_object'
class Project < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon
  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident
  attr_accessor :link_attributes
  
  belongs_to :typesobject
  belongs_to :typeaccess,
  :class_name => "Typesobject"
  belongs_to :statusobject
  belongs_to :owner,
  :class_name => "User"
  belongs_to :group

  has_many :links_documents, :class_name => "Link", :foreign_key => "father_id", :conditions => ["father_plmtype='project' and child_plmtype='document'"]
  has_many :documents , :through => :links_documents

  has_many :links_parts, :class_name => "Link", :foreign_key => "father_id", :conditions => ["father_plmtype='project' and child_plmtype='part'"]
  has_many :parts , :through => :links_parts

  has_many :links_users, :class_name => "Link", :foreign_key => "father_id", :conditions => ["father_plmtype='project' and child_plmtype='user'"]
  has_many :users , :through => :links_users

  has_many :links_customers, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='customer' and child_plmtype='project'"]
  has_many :customers , :through => :links_customers

  def self.create_new(project, user)
    if(project!=nil)
      obj=Project.new(project)
    else
      obj=Project.new
      obj.set_default_values(true)
    end
    obj.owner=user
    obj.group=user.group
    obj.statusobject = Statusobject.get_first("project")
    #puts obj.inspect
    obj
  end

  def link_attributes=(att)
    @link_attributes = att
  end
  def link_attributes
    @link_attributes
  end
  
  # renvoie le nom du projet affecte par defaut au user
  def for_user(username)
    ::SYLRPLM::USER_PROJECT_IDENT+username
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
    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "ident LIKE :v_filter or "+qry_type+" or designation LIKE :v_filter or "+qry_status+
      " or "+qry_owner+" or date LIKE :v_filter "
      ret[:values]={:v_filter => filter}
    end
    ret
    #conditions = ["ident LIKE ? or "+qry_type+" or designation LIKE ? or "+qry_status+
    #  " or "+qry_owner+" or date LIKE ? "
  end

end
