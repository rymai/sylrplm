require 'lib/models/plm_object'
class Customer < ActiveRecord::Base
  
  include PlmObject
  
  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident
  has_many :projects
  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner,
    :class_name => "User",
    :foreign_key => "owner"
    
  def self.createNew(customer,user)
    if(customer!=nil)
      obj=Customer.new(customer)
      #Sequence.set_default_values(obj, self.name, false)
    else
      obj=Customer.new
      #obj.ident=Sequence.get_next_seq("customer")
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
  
  def add_projects_from_favori(favori)
        favori.items.each do |item|
            projects << item
        end    
  end
  
  #def self.getTypesCustomer
  #    Typesobject.find(:all, :order=>"name",
  #      :conditions => ["object = 'customer'"])
  #end
  
  def remove_project(project)
             projects.delete( project)
  end  
   
  def add_documents_from_favori(favori)
        favori.items.each do |item|
          documents << item
        end    
    end
    
  def isFreeze_old
    if(self.statusobject!=nil && Statusobject.find_last(:customer)!=nil)
      if(self.statusobject.rank == Statusobject.find_last(:customer).rank)
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
    if(self.statusobject!=nil && Statusobject.find_last(:customer)!=nil)
      if(self.statusobject.rank == Statusobject.find_last(:customer).rank-1)
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
end
