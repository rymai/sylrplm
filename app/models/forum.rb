class Forum < ActiveRecord::Base
  include Models::SylrplmCommon

  attr_accessor :user

  validates_presence_of :statusobject_id, :typesobject_id, :subject

  belongs_to :typesobject
  belongs_to :statusobject
  belongs_to :owner, :class_name => "User"
  belongs_to :group
  belongs_to :projowner, :class_name => "Project"

  has_many :forum_items, :conditions => { parent_id: nil }

  def initialize(*args)
    super
    self.statusobject = Statusobject.get_first("forum")
    self.set_default_values(true) if args.empty?
  end

  def user=(user)
    self.owner     = user
    self.group     = user.group
    self.projowner = user.project
  end

  def self.create_new(attributes, user)
    raise Exception.new "Don't call this method! Use Forum.new(params[:forum].merge(user: current_user)) instead!"
  end

  alias_method :ident, :subject
  alias_method :designation, :ident

  def find_root_items
    ForumItem.all(order: "updated_at DESC", conditions: ["forum_id = '#{id}' and parent_id is null"])
  end

  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret = {}
    unless filter.nil?
      ret[:qry] = "subject LIKE :v_filter or #{qry_type} or #{qry_owner_id} or #{qry_status}"
      ret[:values] = { v_filter: filter }
    end
    ret
  end
end
