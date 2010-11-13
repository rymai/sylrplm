class Part < ActiveRecord::Base
  include PlmObject
  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident, :scope => :revision
  # dans link has_many :documents
  ##has_many :partslinks
  #belongs_to :typesobject, :conditions => ["object='part'"]
  belongs_to :typesobject
  belongs_to :statusobject
  #has_and_belongs_to_many :projects
  belongs_to :owner,
    :class_name => "User",
    :foreign_key => "owner"
  #
  
  #has_and_belongs_to_many :documents, :join_table => "links",
  #:foreign_key => "father_id", :association_foreign_key => "child_id", :conditions => ["father_object='part' AND child_object='document'"]
  
  has_many :links, :foreign_key => "father_id", :conditions => ["father_object='part'"]
  
  has_many :documents , :through => :links
  
  #def self.getFirstRevision
  #      "A"    
  #end
  
  def self.createNew(part,user)
    if(part!=nil)
      p=Part.new(part)
      #Sequence.set_default_values(p, self.name, false)
    else
      p=Part.new
      Sequence.set_default_values(p, self.name, true)
    end
    #p.revision=getFirstRevision
    p.statusobject=Statusobject.find_first("part")
    p.owner=user
    puts "part.createNew:"+p.inspect
    p
  end
  
  # modifie les attributs avant edition
  def self.find_edit(object_id)
    obj=find(object_id)
    obj.edit
    return obj
  end
  
  def isFreeze
    if(self.statusobject!=nil && Statusobject.find_last("part")!=nil)
      if(self.statusobject.rank == Statusobject.find_last("part").rank)
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
    if(self.statusobject!=nil && Statusobject.find_last("part")!=nil)
      if(self.statusobject.rank == Statusobject.find_last("part").rank-1)
        true
      else
        false
      end
    else
      false
    end 
  end
  
  def self.getTypesPart
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
  
  def revise_old
    if(self.isFreeze)
      # recherche si c'est la derniere revision
      rev_cur=self.revision
      last_rev=find_last_revision(self)
      if(last_rev.revision==rev_cur)
        part=clone()
        part.revision=rev_cur.next
        part.statusobject=Statusobject.find_first("part")
        puts "part.revise:"+part.inspect
        return part
      else
        return nil
      end
    else
      return nil
    end    
  end
  
  
  
end
