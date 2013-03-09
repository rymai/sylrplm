class Document < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon

  attr_accessor :link_attributes, :user

  validates_presence_of :ident , :designation
  validates_uniqueness_of :ident, :scope => :revision
  #validates_format_of :ident, :with => /^(doc|img)[0-9]+$/, :message=>" doit commencer par doc ou img suivi de chiffres"
  validates_format_of :ident, :with => /^([a-z]|[A-Z])+[0-9]+$/ #, :message=>t(:valid_ident,:typeobj =>:ctrl_document)

  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner, :class_name => "User"
  belongs_to :group
  belongs_to :projowner, :class_name => "Project"

  has_many :datafiles, :dependent => :destroy
  has_many :checks

  has_many :links_documents,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => { father_plmtype: 'document', child_plmtype: 'document' }
  has_many :documents,
    :through => :links_documents,
    :source => :document

  has_many :links_documents_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => { father_plmtype: 'document', child_plmtype: 'document' }
  has_many :documents_up ,
    :through => :links_documents_up,
    :source => :document_up

  has_many :links_parts_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => { father_plmtype: 'part', child_plmtype: 'document' }
  has_many :parts_up,
    :through => :links_parts_up,
    :source => :part_up

  has_many :links_projects_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => { father_plmtype: 'project', child_plmtype: 'document' }
  has_many :projects_up,
    :through => :links_projects_up,
    :source => :project_up

  has_many :links_customers_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => { father_plmtype: 'customer', child_plmtype: 'document' }
  has_many :customers_up,
    :through => :links_customers_up,
    :source => :customer_up

  has_many :links_histories_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => { father_plmtype: 'history_entry', child_plmtype: 'document' }
  has_many :histories_up,
    :through => :links_histories_up,
    :source => :history_up

  def user=(user)
		def_user(user)
	end

  #essai, appelle 10 fois par document !!!
  #def after_find
  #puts "Document:after_find: ident="+ident+" type="+model_name+"."+typesobject.name+" proj="+projowner.ident+" group="+group.name
  #end
  def self.create_new(document, user)
    raise Exception.new "Don't use this method!"
  end

  def self.get_conditions(filters)
    filter = filters.gsub("*", "%")
    ret = {}
    unless filter.nil?
      ret[:qry] = "ident LIKE :v_filter or revision LIKE :v_filter or designation LIKE :v_filter or date LIKE :v_filter "
      ret[:values] = { :v_filter => filter }
    end
    ret
  end

  def self.get_types_document
    Typesobject.find(:all, :order => "name",
    :conditions => ["forobject = 'document'"])
  end

  def self.find_all
    find(:all, :order => "ident ASC, revision ASC")
  end

  def self.find_with_part
    find(:all,
    :conditions => ["part_id IS NOT NULL"],
    :order => "ident")
  end

  def self.find_without_part
    find(:all,
    :conditions => ["part_id IS NULL"],
    :order => "ident")
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
    obj = find(object_id)
    obj.edit
    obj
  end
  
  #pour par exemple interdire les fichiers dans un répertoire
  def directory? 
  	typesobject.name==::SYLRPLM::TYPE_DOC_DIRECTORY 
  end
  
  def get_check_out
  	Check.get_checkout(self)
  end
  
	def can_be_check_in?(user)
		chk = get_check_out
		ret=false
		unless chk.nil?
			ret=user==chk.out_user
		end
		ret
	end
  
  def check_out(params, user)
    fname= "#{self.class.name}.#{__method__}"
    LOG.info (fname){"params=#{params}, user=#{user.inspect}"} 
    ret = ""
    if Check.get_checkout(self).nil?
      unless params[:out_reason].blank?
        args={}
        args[:out_reason] = params[:out_reason]
        args[:checkobject] = self.model_name
        args[:checkobject_id] = self.id
        args[:user] = user
        
       ## if Check.create(params.merge(object_to_check: self, user: user))
        if Check.create(args)
          ret = "ok"
        else
          ret = "notcheckout"
        end
      else
        ret = "no_reason"
      end
    else
      ret = "already_checkout"
    end
    LOG.info (fname){"ret=#{ret}"} 
    ret
  end

  def check_in(params,user)
    if check = Check.get_checkout(self)
      check.update_accessor(user)
      check.checkIn(params, user)
      if check.save
        self.update_attributes(params[:document])
        "ok"
      else
        check.errors[:in_reason].present? ? "no_reason" : "notcheckin"
      end
    else
      "notyet_checkout"
    end
  end

  def check_free(params,user)
    if check = Check.get_checkout(self)
      check.update_accessor(user)
      check.checkFree(params,user)
      if check.save
        self.update_attributes(params[:document])
        "ok"
      else
        check.errors[:in_reason].present? ? "no_reason" : "notcheckfree"
      end
    else
      "notyet_checkout"
    end
  end

  def checked?
    Check.get_checkout(self).present?
  end

  def add_datafile(params,user)
    fname= "#{self.class.name}.#{__method__}"
    LOG.info (fname){"params=#{params}, user=#{user.inspect}"} 
    #datafile = Datafile.new(params.merge(user: user))
    datafile = Datafile.new(params)
    datafile.document = self
    if datafile.save
      self.datafiles << datafile
      self.save
      "ok"
    else
      "datafile_not_saved"
    end
  end

  def remove_datafile(item)
    self.datafiles.delete(item)
  end

  def get_datafiles
    ret = []
    ret = self.datafiles
    ret = { :recordset => ret, :total => ret.length }

    ret
  end
  
  def variants
  	nil
  end
  
	def users
		nil
	end

end
