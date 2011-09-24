class Document < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon

  attr_accessor :link_attributes
  validates_presence_of :ident , :designation
  validates_uniqueness_of :ident, :scope => :revision
  #validates_format_of :ident, :with =>/^(doc|img)[0-9]+$/, :message=>" doit commencer par doc ou img suivi de chiffres"
  validates_format_of :ident, :with =>/^([a-z]|[A-Z])+[0-9]+$/ #, :message=>t(:valid_ident,:typeobj =>:ctrl_document)

  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner,
  :class_name => "User"
  belongs_to :group

  has_many :datafile
  has_many :checks

  has_many :links_documents, :class_name => "Link", :foreign_key => "father_id", :conditions => ["father_plmtype='document' and child_plmtype='document'"]
  has_many :documents , :through => :links_documents

  has_many :links_parts, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='part' and child_plmtype='document'"]
  has_many :parts, :through => :links_parts

  has_many :links_projects, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='project' and child_plmtype='document'"]
  has_many :projects, :through => :links_projects

  has_many :links_customers, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='customer' and child_plmtype='document'"]
  has_many :customers, :through => :links_customers

  def to_s
    "#{self.ident}/#{self.revision}-#{self.designation}-#{self.typesobject.try(:name)}-#{self.statusobject.try(:name)}"
  end

  def self.create_new(document, user)
    unless document.nil?
      doc = Document.new(document)
    else
      #doc = user.documents.build(:ident => Sequence.get_next_seq("Document.ident"))
      doc = Document.new()
      doc.set_default_values(true)
    end
    doc.owner=user
    doc.group=user.group
    doc.statusobject = Statusobject.get_first("document")
    doc
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

  def check_out(params,user)
    ret=""
    check     = Check.get_checkout("document", self)
    if check.nil?
      unless params[:out_reason].blank?
        check = Check.create_new("document", self, params, user)
        if check.save
          ret="ok"
        else
          ret="notcheckout"
        end
      else
        ret="no_reason"
      end
    else
      ret="already_checkout"
    end
  end

  def check_in(params,user)
    ret=""
    check     = Check.get_checkout("document", self)
    unless params[:in_reason].blank?
      unless check.nil?
        check.checkIn(params,user)
        if check.save
          self.update_attributes(params[:document])
          ret="ok"
        else
          ret="notcheckin"
        end
      else
        ret="notyet_checkout"
      end
    else
      ret="no_reason"
    end
  end

  def check_free(params,user)
    ret=""
    check     = Check.get_checkout("document", self)
    unless params[:in_reason].blank?
      unless check.nil?
        check.checkFree(params,user)
        if check.save
          self.update_attributes(params[:document])
          ret="ok"
        else
          ret="notcheckfree"
        end
      else
        ret="notyet_checkout"
      end
    else
      ret="no_reason"
    end
  end

  def checked?
    !Check.get_checkout("document", self).nil?
  end

  def frozen?
    !(self.statusobject.nil? || Statusobject.get_last("document").nil?) &&
    self.statusobject.rank == Statusobject.get_last("document").rank
  end
  
  
  
  def self.get_types_document
    Typesobject.find(:all, :order=>"name",
    :conditions => ["object = 'document'"])
  end

  def add_datafile(params,user)
    ret=""
    datafile = Datafile.create_new(params, user)
    if datafile.save
      self.datafile << datafile
      self.save
      ret="ok"
    else
      ret="datafile_not_saved"
    end
  end

  def get_datafiles
    ret=[]
    ret=self.datafile
    ret={:recordset=>ret,:total=>ret.length}
    #puts "document.get_datafiles:"+ret.inspect
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

  def last_revision
    Document.find(:last, :order=>"revision ASC",  :conditions => ["ident = '#{ident}'"])
  end

  def promote
    st_cur_name = statusobject.name
    st_new = statusobject.get_next
    update_attributes({:statusobject_id => st_new.id})
    puts "Document.promote:"+st_cur_name+" -> "+st_new.name+":"+statusobject.name
  end

  def demote
    st_cur_name = statusobject.name
    st_new = statusobject.get_previous
    update_attributes({:statusobject_id => st_new.id})
    puts "Document.demote:"+st_cur_name+" -> "+st_new.name+":"+statusobject.name
  end

  def remove_datafile(item)
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
      filter, filter,
      filter, filter,
      filter, filter,
      filter ] unless filter.nil?
  end

 
 
  
end
