# frozen_string_literal: true

class Customer < ActiveRecord::Base
  include Models::SylrplmCommon
  include Models::PlmObject

  attr_accessor :link_attributes, :user
  attr_accessible :id, :owner_id, :typesobject_id, :statusobject_id, :next_status_id, :previous_status_id
  attr_accessible :ident, :revision, :designation, :description, :date, :owner, :group_id, :projowner_id, :domain, :type_values

  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident

  has_many :datafiles, dependent: :destroy

  # rails2 has_many :thumbnails, -> { where(father_plmtype: 'document'  , child_plmtype: 'document') },  	:class_name => "Datafile",  	:conditions => "typesobject_id = (select id from typesobjects as t where t.name='thumbnail')"
  has_many :thumbnails, -> { where "typesobject_id = (select id from typesobjects as t where t.name='thumbnail')" },	class_name: 'Datafile'

  has_many :projects

  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :next_status, class_name: 'Statusobject'
  belongs_to :previous_status, class_name: 'Statusobject'
  belongs_to :owner, class_name: 'User'
  belongs_to :group
  belongs_to :projowner, class_name: 'Project'

  # rails2 has_many :links_customer_forums,    :class_name => "Link",    :foreign_key => "father_id",    :conditions => { father_plmtype: 'customer', child_plmtype: 'forum' }
  has_many :links_customer_forums, -> { where(father_plmtype: 'customer', child_plmtype: 'forum') }, class_name: 'Link', foreign_key: 'father_id'
  has_many :forums, through: :links_customer_forums, source: :forum

  # rails2 has_many :links_customer_documents,    :class_name => "Link",    :foreign_key => "father_id",    :conditions => ["father_plmtype='customer' and child_plmtype='document'"]
  has_many :links_customer_documents, -> { where(father_plmtype: 'customer', child_plmtype: 'document') }, class_name: 'Link', foreign_key: 'father_id'
  has_many :documents, through: :links_customer_documents, source: :document_down

  # rails2  has_many :links_customer_projects,    :class_name => "Link",    :foreign_key => "father_id",    :conditions => ["father_plmtype='customer' and child_plmtype='project'"]
  has_many :links_customer_projects, -> { where(father_plmtype: 'customer', child_plmtype: 'project') }, class_name: 'Link', foreign_key: 'father_id'
  has_many :projects, through: :links_customer_projects, source: :project_down

  def user=(user)
    def_user(user)
  end

  def self.create_new(_customer, _user)
    raise Exception, "Don't use this method!"
  end

  # modifie les attributs avant edition
  def self.find_edit(customer_id)
    find(customer_id).tap(&:edit)
  end

  def add_projects_from_clipboard(clipboard)
    projects += clipboard.items
  end

  def remove_project(project)
    projects.delete(project)
  end

  def add_documents_from_clipboard(clipboard)
    documents += clipboard.items
  end

  def self.get_conditions(filters)
    filter = filters.tr('*', '%')
    ret = {}
    unless filter.nil?
      ret[:qry] = "ident LIKE :v_filter or designation LIKE :v_filter or #{qry_type} or #{qry_status} or #{qry_owner_id} or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
      ret[:values] = { v_filter: filter }
    end
    ret
    #  TODO
    #   filter=filter.gsub("*","%")
    #   ["ident LIKE ? or "+qry_type+" or designation LIKE ? or "+qry_status+
    #   " or "+qry_owner+" or date LIKE ? ",
    #   filter, filter,
    #   filter, filter,
    #   filter, filter ] unless filter.nil?
  end

  def variants
    nil
  end

  def users
    [nil]
  end

  #
  # this object could have a 3d or 2d model show in tree
  #
  def have_model_design?
    false
  end
end
