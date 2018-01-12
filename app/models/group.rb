# frozen_string_literal: true

#
# A group of users
#
class Group < ActiveRecord::Base
  include Models::SylrplmCommon
  attr_accessible :id, :name, :father_id, :domain

  # has_many :user_groups, :dependent => :delete_all
  # has_many :users, :through => :user_groups
  validates_presence_of :name
  validates_uniqueness_of :name
  has_and_belongs_to_many :users, join_table: :groups_users

  has_and_belongs_to_many :subscriptions, join_table: :groups_subscriptions
  # has_many :group_definitions, :dependent => :delete_all
  # has_many :definitions, :through => :group_definitions
  has_and_belongs_to_many :volumes, join_table: :groups_volumes
  has_many :childs, class_name: 'Group', primary_key: 'id', foreign_key: 'father_id'
  belongs_to :father, class_name: 'Group'
  #
  # User and Group share this method, which returns login and name respectively
  #
  def ident
    name
 end

  def system_name
    name
 end

  def designation
    name
 end

  def name_translate
    PlmServices.translate("group_name_#{name}")
  end

  # ruse pour export excel, la colonne father_tr est commune a role et group
  def title_translate
    name_translate
  end

  def variants
    nil
  end

  def revisable?
    false
  end

  def typesobject
    Typesobject.find_by_forobject(modelname).to_a[0]
  end

  def father_name
    father.try(:name) || ''
  end

  def may_launch_untracked_process?
    definitions.detect { |d| d.name == '*untracked*' }
  end

  def may_launch_embedded_process?
    definitions.detect { |d| d.name == '*embedded*' }
  end

  def self.get_conditions(filter)
    filter = filters.tr('*', '%')
    ret = {}
    unless filter.nil?
      ret[:qry] = "name LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
      ret[:values] = { v_filter: filter }
    end
    ret
  end

  def others
    Group.all
  end
end
