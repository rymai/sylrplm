class Customer < ActiveRecord::Base
  include Models::SylrplmCommon
  include Models::PlmObject

  attr_accessor :link_attributes, :user

  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident

  has_many :projects

  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner, :class_name => "User"
  belongs_to :group
  belongs_to :projowner, :class_name => "Project"

  has_many :links_documents,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => ["father_plmtype='customer' and child_plmtype='document'"]
  has_many :documents,
    :through => :links_documents,
    :source => :document

  has_many :links_projects,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => ["father_plmtype='customer' and child_plmtype='project'"]
  has_many :projects ,
    :through => :links_projects,
    :source => :project

  def initialize(*args)
    super
    self.statusobject = Statusobject.get_first("customer")
    self.set_default_values(true) if args.length==1
  end

  def user=(user)
    self.owner     = user
    self.group     = user.group
    self.projowner = user.project
  end

  def self.create_new(customer, user)
    raise Exception.new "Don't use this method!"
  end

  # modifie les attributs avant edition
  def self.find_edit(customer_id)
    find(customer_id).tap { |customer| customer.edit }
  end

  def add_projects_from_favori(favori)
    # favori.items.each do |item|
    #   projects << item
    # end
    projects += favori.items # this should work the same
  end

  def remove_project(project)
    projects.delete(project)
  end

  def add_documents_from_favori(favori)
    # favori.items.each do |item|
    #   documents << item
    # end
    documents += favori.items # this should work the same
  end

  def self.get_conditions(filter)
    filter = filters.gsub("*", "%")
    ret = {}
    unless filter.nil?
      ret[:qry] = "ident LIKE :v_filter or designation LIKE :v_filter or :qry_type or :qry_status or :qry_owner"
      ret[:values] = { v_filter: filter, qry_type: qry_type, qry_status: qry_status, qry_owner: qry_owner }
    end
    ret
=begin  TODO
    filter=filter.gsub("*","%")
    ["ident LIKE ? or "+qry_type+" or designation LIKE ? or "+qry_status+
      " or "+qry_owner+" or date LIKE ? ",
      filter, filter,
      filter, filter,
      filter, filter ] unless filter.nil?
=end
  end
end
