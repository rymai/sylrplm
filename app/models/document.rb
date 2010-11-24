require 'lib/models/plm_object'
class Document < ActiveRecord::Base
  include PlmObject
  
  validates_presence_of :ident , :designation 
  validates_uniqueness_of :ident, :scope => :revision
  #validates_format_of :ident, :with =>/^(doc|img)[0-9]+$/, :message=>" doit commencer par doc ou img suivi de chiffres"
  validates_format_of :ident, :with =>/^([a-z]|[A-Z])+[0-9]+$/, :message=>" doit commencer par des lettres suivi de chiffres"

  #belongs_to :typesobject, :conditions => ["object='part'"]
  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :volume
  belongs_to :owner,
    :class_name => "User",
    :foreign_key => "owner"
  
  has_many :checks
  has_many :links, :foreign_key => "father_id", :conditions => ["father_object='document'"]
  has_many :datafiles , :through => :links
  
  before_create :set_initial_attributes
  
  #def self.getFirstRevision
  #    "00100"    
  #end
  
  def self.createNew(document, user)
    if(document!=nil)
      puts "document.createNew:"+document.inspect
      doc = Document.new(document)
      #Sequence.set_default_values(doc, self.name, false)
    else
      #doc = user.documents.build(:ident => Sequence.get_next_seq("Document.ident"))    
      doc = Document.new  
      Sequence.set_default_values(doc, self.name, true)
      doc.volume = Volume.find(1) 
    end
    doc.owner=user
    doc.statusobject = Statusobject.find_first("document")
    puts "document.createNew:"+doc.inspect
    doc
  end
  
  def set_initial_attributes
    
  end
  
  # modifie les attributs avant edition
  def self.find_edit(object_id)
    obj=find(object_id)
    obj.edit
    return obj
  end
  
  def is_checked
    check=Check.findCheckout("document", self) 
    file=self.filename
    if(check.nil?)
      #non reserve
      false
    else
      #reserve
      true
    end
  end
  
  def isFreeze
    if(self.statusobject!=nil && Statusobject.find_last("document")!=nil)
      if(self.statusobject.rank == Statusobject.find_last("document").rank)
        true
      else
        false
      end
    else
      false
    end
  end
  
  # a valider si avant dernier status
  def isToValidate
    if(self.statusobject!=nil && Statusobject.find_last("document")!=nil)
      if(self.statusobject.rank == Statusobject.find_last("document").rank-1)
        true
      else
        false
      end
    else
      false
    end 
  end
  
  def self.getTypesDocument 
    Typesobject.find(:all, :order=>"name",
      :conditions => ["object = 'document'"])
  end
  def getDatafiles
    ret=[]
    links=Link.find_childs("document", self,  "datafile")
    links.each do |link|
      child=Datafile.find(link.child_id)
      ret<<child
    end
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
  
#  def uploaded_file=(file_field)
#    puts "document.uploaded_file"+file_field.inspect
#    if file_field != nil
#      self.removeFile
#      fname=base_part_of(file_field.original_filename)
#      self.filename=fname
#      self.content_type=file_field.content_type.chomp
#      content=file_field.read
#      writeFile(content)
#    end
#  end
  
#  def base_part_of(file_name)
#    File.basename(file_name).gsub(/[^\w._-]/, '')    
#  end
  
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
  
  
  
end
