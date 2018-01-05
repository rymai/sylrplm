# frozen_string_literal: true

# require 'lib/models/plm_object'
class Project < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon
  validates_presence_of :ident, :designation
  validates_uniqueness_of :ident, scope: :revision

  attr_accessor :user, :link_attributes
  attr_accessible :id, :owner_id, :typesobject_id, :statusobject_id, :next_status_id, :previous_status_id
  attr_accessible :ident, :revision, :designation, :description, :date, :owner, :group_id, :typeaccess_id, :domain, :type_values

  has_many :datafiles, dependent: :destroy

  # rails2 has_many :thumbnails,  	:class_name => "Datafile",  	:conditions => "typesobject_id = (select id from typesobjects as t where t.name='thumbnail')"
  has_many :thumbnails, -> { where("typesobject_id = (select id from typesobjects as t where t.name='thumbnail')") },	class_name: 'Datafile'

  belongs_to :typesobject
  belongs_to :typeaccess,
             class_name: 'Typesobject'
  belongs_to :statusobject
  belongs_to :next_status, class_name: 'Statusobject'
  belongs_to :previous_status, class_name: 'Statusobject'
  belongs_to :owner, class_name: 'User'
  belongs_to :group

  has_and_belongs_to_many :users, join_table: :projects_users

  has_and_belongs_to_many :subscriptions, join_table: :projects_subscriptions
  # has_many :projects_users, :dependent => :delete_all
  # has_many :users, :through => :projects_users

  # rails2 has_many :links_project_forums,    :class_name => "Link",    :foreign_key => "father_id",    :conditions => { father_plmtype: 'project', child_plmtype: 'forum' }
  has_many :links_project_forums, -> { where(father_plmtype: 'project', child_plmtype: 'forum') }, class_name: 'Link', foreign_key: 'father_id'
  has_many :forums, through: :links_project_forums, source: :forum

  # rails2 has_many :links_project_documents,    :class_name => "Link",    :foreign_key => "father_id",    :conditions => ["father_plmtype='project' and child_plmtype='document'"]
  has_many :links_project_documents, -> { where(father_plmtype: 'project', child_plmtype: 'document') }, class_name: 'Link', foreign_key: 'father_id'
  has_many :documents, through: :links_project_documents, source: :document_down

  # rails2 has_many :links_project_parts,    :class_name => "Link",    :foreign_key => "father_id",    :conditions => ["father_plmtype='project' and child_plmtype='part'"]
  has_many :links_project_parts, -> { where(father_plmtype: 'project', child_plmtype: 'part') }, class_name: 'Link', foreign_key: 'father_id'
  has_many :parts, through: :links_project_parts, source: :part_down

  # rails2 has_many :links_project_customers_up,    :class_name => "Link",    :foreign_key => "child_id",    :conditions => ["father_plmtype='customer' and child_plmtype='project'"]
  has_many :links_project_customers_up, -> { where(father_plmtype: 'project', child_plmtype: 'customer') }, class_name: 'Link', foreign_key: 'child_id'
  has_many :customers_up, through: :links_project_customers_up, source: :customer_up
  #
  def user=(user)
    def_user(user)
  end

  def name_translate
    ident
  end

  # renvoie le nom du projet affecte par defaut au user
  def self.for_user(username)
    PlmServices.get_property(:USER_PROJECT_IDENT) + username
  end

  # modifie les attributs avant edition
  def self.find_edit(object_id)
    obj = find(object_id)
    obj.edit
    obj
  end

  def add_parts_from_clipboard(clipboard)
    clipboard.items.each do |item|
      parts << item
    end
  end

  def remove_parts
    parts = nil
  end

  def remove_part(item)
    parts.delete(item)
  end

  def self.get_conditions(filter)
    filter = filters.tr('*', '%')
    ret = {}
    unless filter.nil?
      ret[:qry] = 'ident LIKE :v_filter or ' + qry_type + ' or designation LIKE :v_filter or ' + qry_status +
                  ' or ' + qry_owner + " or to_char(date, 'YYYY/MM/DD') LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter "
      ret[:values] = { v_filter: filter }
    end
    ret
    # conditions = ["ident LIKE ? or "+qry_type+" or designation LIKE ? or "+qry_status+
    #  " or "+qry_owner+" or date LIKE ? "
  end

  def variants
    nil
  end

  #
  # this object could have a 3d or 2d model show in tree
  #
  def have_model_design?
    false
  end
end
