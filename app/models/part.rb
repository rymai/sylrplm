#require 'lib/models/plm_object'
class Part < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon
  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident, :scope => :revision

  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner,
    :class_name => "User",
    :foreign_key => "owner"
  #
  
  #has_and_belongs_to_many :documents, :join_table => "links",
  #:foreign_key => "father_id", :association_foreign_key => "child_id", :conditions => ["father_object='part' AND child_object='document'"]
  
  has_many :links_documents,:class_name => "Link", :foreign_key => "father_id", :conditions => ["father_object='part' and child_object='document'"]
  has_many :documents , :through => :links_documents
  has_many :links_parts,:class_name => "Link", :foreign_key => "child_id", :conditions => ["father_object='part' and child_object='part'"]
  has_many :parts , :through => :links_parts
  has_many :links_projects,:class_name => "Link", :foreign_key => "child_id", :conditions => ["father_object='project' and child_object='part'"]
  has_many :projects , :through => :links_projects
  has_many :links_customers,:class_name => "Link", :foreign_key => "child_id", :conditions => ["father_object='customer' and child_object='part'"]
  has_many :customers , :through => :links_customers

  def self.create_new(part,user)
    if(part!=nil)
      p=Part.new(part)
    else
      p=Part.new
      p.set_default_values(true)
    end
    p.statusobject=Statusobject.get_first("part")
    p.owner=user
    puts "part.create_new:"+p.inspect
    p
  end
  
  # modifie les attributs avant edition
  def self.find_edit(object_id)
    obj=find(object_id)
    obj.edit
    obj
  end
  
  def is_freeze
    if(self.statusobject!=nil && Statusobject.get_last("part")!=nil)
      if(self.statusobject.rank == Statusobject.get_last("part").rank)
        true
      else
        false
      end
    else
      false
    end
  end
  
  # a valider si avant dernier status
  def is_to_validate
    if(self.statusobject!=nil && Statusobject.get_last("part")!=nil)
      if(self.statusobject.rank == Statusobject.get_last("part").rank-1)
        true
      else
        false
      end
    else
      false
    end 
  end
  
  def self.get_types_part
    Typesobject.find(:all, :order=>"name",
        :conditions => ["object = 'part'"])
  end
  def self.find_all
    find(:all, :order=>"ident")
  end 
  def self.find_others(part_id)
    find(:all,
        :conditions => ["id != #{part_id}"],
        :order=>"ident")
  end 
  
  def add_documents_from_favori(favori)
    favori.items.each do |item|
      documents << item
    end    
  end
  
  def remove_documents()
    documents =nil  
  end
  
  def remove_document(document)
    documents.delete( document)
  end 
  
  def add_projects_from_favori(favori)
    favori.items.each do |item|
      projects << item
    end    
  end
  
  def remove_projects()
    projects =nil  
  end
  
  def remove_project(item)
    projects.delete( item)
  end 
  def find_last_revision(object)
    Part.find(:last, :order=>"revision ASC",  :conditions => ["ident = '#{object.ident}'"])
  end
  def promote
    next_status=Statusobject.find_next("part",statusobject)
    self.statusobject=next_status 
    self   
  end 
  def self.get_conditions(filter)
     filter=filter.gsub("*","%")
     conditions = ["ident LIKE ? or "+qry_type+" or revision LIKE ? or designation LIKE ? or "+qry_status+
      " or "+qry_owner+" or date LIKE ? ",
      filter, filter, 
    filter, filter, 
    filter, filter, 
    filter ] unless filter.nil? 
  end
  
end
