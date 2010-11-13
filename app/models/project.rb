class Project < ActiveRecord::Base
  include PlmObject
  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident
  belongs_to :customer
  belongs_to :typesobject
  belongs_to :statusobject
  has_and_belongs_to_many :parts
  belongs_to :owner,
    :class_name => "User",
    :foreign_key => "owner"

  def self.createNew(project, user)
      if(project!=nil)
          obj=Project.new(project)
          #Sequence.set_default_values(obj, self.name, false)
      else
          obj=Project.new
          #obj.ident=Sequence.get_next_seq("project")
          Sequence.set_default_values(obj, self.name, true)
      end
      obj.owner=user
      puts obj.inspect
      obj
  end
    
  # modifie les attributs avant edition
  def self.find_edit(object_id)
    obj=find(object_id)
    obj.edit
    return obj
  end
  
  def self.getTypesProject 
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
    
 
end
