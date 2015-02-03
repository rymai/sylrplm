class Customer < ActiveRecord::Base
  include Models::SylrplmCommon
  include Models::PlmObject

  attr_accessor :link_attributes, :user

  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident

  has_many :datafiles, :dependent => :destroy

  has_many :thumbnails,
  	:class_name => "Datafile",
  	:conditions => "typesobject_id = (select id from typesobjects as t where t.name='thumbnail')"


  has_many :projects

  belongs_to :typesobject
  belongs_to :statusobject
	belongs_to :next_status, :class_name => "Statusobject"
	belongs_to :previous_status, :class_name => "Statusobject"
  belongs_to :owner, :class_name => "User"
  belongs_to :group
  belongs_to :projowner, :class_name => "Project"

	has_many :links_customer_forums,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => { father_plmtype: 'customer', child_plmtype: 'forum' }
	has_many :forums,
    :through => :links_customer_forums,
    :source => :forum

  has_many :links_customer_documents,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => ["father_plmtype='customer' and child_plmtype='document'"]
  has_many :documents,
    :through => :links_customer_documents,
    :source => :document_down

  has_many :links_customer_projects,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => ["father_plmtype='customer' and child_plmtype='project'"]
  has_many :projects ,
    :through => :links_customer_projects,
    :source => :project_down

  def user=(user)
		def_user(user)
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

  def self.get_conditions(filters)
    filter = filters.gsub("*", "%")
    ret = {}
    unless filter.nil?
      ret[:qry] = "ident LIKE :v_filter or designation LIKE :v_filter or #{qry_type} or #{qry_status} or #{qry_owner_id} or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
      ret[:values] = { v_filter: filter }
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
			true
	end
end
