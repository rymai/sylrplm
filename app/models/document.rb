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
  belongs_to :projowner,
    :class_name => "Project"

  has_many :datafiles, :dependent => :destroy
  has_many :checks

  has_many :links_childs_documents, :class_name => "Link", :foreign_key => "father_id", :conditions => ["father_plmtype='document' and child_plmtype='document'"]
  has_many :childs_documents , :through => :links_childs_documents , :source => :document
  has_many :links_fathers_documents, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='document' and child_plmtype='document'"]
  has_many :fathers_documents , :through => :links_fathers_documents, :source => :document

  has_many :links_fathers_parts, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='part' and child_plmtype='document'"]
  has_many :fathers_parts, :through => :links_fathers_parts, :source => :part

  has_many :links_fathers_projects, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='project' and child_plmtype='document'"]
  has_many :fathers_projects, :through => :links_fathers_projects, :source => :project

  has_many :links_fathers_customers, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='customer' and child_plmtype='document'"]
  has_many :fathers_customers, :through => :links_fathers_customers, :source => :customer

  has_many :links_fathers_histories, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='history_entry' and child_plmtype='document'"]
  has_many :fathers_histories, :through => :links_fathers_histories, :source => :history_entry
  #essai, appelle 10 fois par document !!!
  #def after_find
  #puts "Document:after_find: ident="+ident+" type="+model_name+"."+typesobject.name+" proj="+projowner.ident+" group="+group.name
  #end
  def self.create_new(document, user)
    unless document.nil?
      obj = Document.new(document)
    else
    #obj = user.documents.build(:ident => Sequence.get_next_seq("Document.ident"))
      obj = Document.new()
    obj.set_default_values(true)
    end
    obj.owner=user
    obj.group=user.group
    obj.projowner=user.project
    obj.statusobject = Statusobject.get_first("document")
    obj
  end

  def self.get_conditions(filters)
    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "ident LIKE :v_filter or revision LIKE :v_filter or designation LIKE :v_filter or date LIKE :v_filter "
      ret[:values]={:v_filter => filter}
    end
    ret
  end

  def self.get_types_document
    Typesobject.find(:all, :order=>"name",
    :conditions => ["object = 'document'"])
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

  def to_s
    "#{self.ident}/#{self.revision}-#{self.designation}-#{self.typesobject.try(:name)}-#{self.statusobject.try(:name)}"
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
    check     = Check.get_checkout(self)
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
    check     = Check.get_checkout(self)
    unless params[:in_reason].blank?
      unless check.nil?
        check.update_accessor(user)
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
    check     = Check.get_checkout(self)
    unless params[:in_reason].blank?
      unless check.nil?
        check.update_accessor(user)
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
    !Check.get_checkout(self).nil?
  end

  def add_datafile(params,user)
    ret=""
    datafile = Datafile.create_new(params, user)
    if datafile.save
      self.datafiles << datafile
      self.save
      ret="ok"
    else
      ret="datafile_not_saved"
    end
  end

  def remove_datafile(item)
    self.datafile.delete(item)
  end

  def get_datafiles
    ret=[]
    ret=self.datafiles
    ret={:recordset=>ret,:total=>ret.length}
    #puts "document.get_datafiles:"+ret.inspect
    ret
  end

end
