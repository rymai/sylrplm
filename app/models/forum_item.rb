# frozen_string_literal: true

class ForumItem < ActiveRecord::Base
  # pour def_user seulement
  include Models::PlmObject
  include Models::SylrplmCommon

  attr_accessor :user
  attr_accessible :id, :forum_id, :parent_id, :owner_id, :message, :group_id, :projowner_id, :domain

  validates_presence_of :forum_id, :message

  belongs_to :author,
             class_name: 'User',
             foreign_key: 'owner_id'
  belongs_to :group
  belongs_to :projowner,
             class_name: 'Project'

  belongs_to :parent,
             class_name: 'ForumItem',
             foreign_key: 'parent_id'

  belongs_to :forum

  has_many :forum_item,
           class_name: 'ForumItem',
           foreign_key: 'parent_id'

  def user=(user)
    def_user(user)
  end

  def forum=(forum)
    fname = "#{self.class.name}.#{__method__}"
    LOG.info(fname) { "forum=#{forum}" }
    self.forum_id = forum.id
  end

  def initialize(*args)
    super
    fname = "#{self.class.name}.#{__method__}"
    LOG.info(fname) { "args=#{args.length}:#{args.inspect}" }
    if args.length >= 1
      LOG.info(fname) { "message=#{args[0][:message]}" }
      self.message = args[0][:message]
    end
  end

  def ident
    "#{id}.#{message}"
  end

  def self.get_conditions(filter)
    filter = filters.tr('*', '%')
    ret = {}
    unless filter.nil?
      ret[:qry] = "message LIKE :v_filter or #{qry_type} or #{qry_owner_id} or #{qry_status}"
      ret[:values] = { v_filter: filter }
    end
    ret
  end
end
