class Document < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon
  validates_presence_of :ident , :designation 
  validates_uniqueness_of :ident, :scope => :revision
  #validates_format_of :ident, :with =>/^(doc|img)[0-9]+$/, :message=>" doit commencer par doc ou img suivi de chiffres"
  validates_format_of :ident, :with =>/^([a-z]|[A-Z])+[0-9]+$/ #, :message=>t(:valid_ident,:object=>:ctrl_document)
  
  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :volume
  belongs_to :owner,
    :class_name => "User",
    :foreign_key => "owner"
  
  has_many :datafile
  has_many :checks
  
  has_many :links_parts,:class_name => "Link", :foreign_key => "child_id", :conditions => ["father_object='part' and child_object='document'"]
  has_many :parts , :through => :links_parts
  
  has_many :links_projects,:class_name => "Link", :foreign_key => "child_id", :conditions => ["father_object='project' and child_object='document'"]
  has_many :projects , :through => :links_projects
  
  has_many :links_customers,:class_name => "Link", :foreign_key => "child_id", :conditions => ["father_object='customer' and child_object='document'"]
  has_many :customers , :through => :links_customers
  
  before_create :set_initial_attributes
  
  def self.create_new(document, user)
    unless document.nil?
      doc = Document.new(document)
    else
      #doc = user.documents.build(:ident => Sequence.get_next_seq("Document.ident"))    
      doc = Document.new 
      doc.set_default_values(true)
      doc.volume = Volume.find(1) 
    end
    doc.owner=user
    doc.statusobject = Statusobject.get_first("document")
    doc
  end
  
  def set_initial_attributes
    
  end
  
  # modifie les attributs avant edition
  def self.find_edit(object_id)
    obj=find(object_id)
    obj.edit
    obj
  end
  
  def is_checked
    check=Check.findCheckout("document", self) 
    if(check.nil?)
      #non reserve
      false
    else
      #reserve
      true
    end
  end
  
  def is_freeze
    if(self.statusobject!=nil && Statusobject.get_last("document")!=nil)
      if(self.statusobject.rank == Statusobject.get_last("document").rank)
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
    if(self.statusobject!=nil && Statusobject.get_last("document")!=nil)
      if(self.statusobject.rank == Statusobject.get_last("document").rank-1)
        true
      else
        false
      end
    else
      false
    end 
  end
  
  def self.get_types_document 
    Typesobject.find(:all, :order=>"name",
      :conditions => ["object = 'document'"])
  end
  def get_datafiles
    ret=[]
    ret=self.datafile
    ret={:recordset=>ret,:total=>ret.length}
    puts "document.get_datafiles:"+ret.inspect
    ret
  end
  
  def self.find_all
    find(:all, :order=>"ident ASC, revision ASC")
  end 
  
  def self.find_with_part
    find(:all,
      :conditions => ["part_id IS NOT NULL"],
      :order=>"ident")
  end 
  
  def self.find_without_part
    find(:all,
      :conditions => ["part_id IS NULL"],
      :order=>"ident")
  end  
  
  def find_last_revision(object)
    Document.find(:last, :order=>"revision ASC",  :conditions => ["ident = '#{object.ident}'"])
  end
  
  def promote
    self.statusobject=Statusobject.find_next("document",statusobject) 
    self   
  end
  
  def demote
    self.statusobject=Statusobject.find_previous("document",statusobject) 
    self   
  end
  
  def remove_datafile(item)
    item.remove_file
    self.datafile.delete(item)
  end
  
  def delete
    self.datafile.each { |file|
      self.remove_datafile(file)
    }
    self.destroy
  end
  
  def self.get_conditions(filter)
    filter=filter.gsub("*","%")
    conditions = ["ident LIKE ? or "+qry_type+" or revision LIKE ? or designation LIKE ? or "+qry_status+
      " or "+qry_owner+" or date LIKE ? ",
      "#{filter}", "#{filter}", 
    "#{filter}", "#{filter}", 
    "#{filter}", "#{filter}", 
    "#{filter}" ] unless filter.nil?
  end
  
end
