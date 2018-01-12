# frozen_string_literal: true

class Role < ActiveRecord::Base
  include Models::SylrplmCommon

  attr_accessible :id, :title, :description, :father_id, :domain

  validates_presence_of :title
  validates_uniqueness_of :title

  has_and_belongs_to_many :users, join_table: :roles_users
  has_and_belongs_to_many :definitions, join_table: :definitions_roles

  belongs_to :father, class_name: 'Role'
  has_many :childs, class_name: 'Role', primary_key: 'id', foreign_key: 'father_id'
  def self.find_by_name(name)
    # TODO: verifier
    where("title = '#{name}' ").first
  end

  def self.findall_except_admin
    # TODO: verifier
    where("title <> 'admin' ").all.to_a
  end

  def self.get_all
    Role.all
  end

  def name
    title
  end

  def father_name
    (father ? father.title : '')
  end

  def ident
    title
 end

  def typesobject
    Typesobject.find_by_forobject(modelname).to_a[0]
  end

  def title_translate
    PlmServices.translate("role_title_#{title}")
  end

  def designation
    Role.truncate_words(description, 5)
  end

  def variants
    nil
  end

  def revisable?
    false
  end

  # return the list of validers
  def self.get_validers
    ret = []
    all.where("title like 'valid%'").to_a.each do |role|
      role.users.each do |user|
        ret << user
      end
    end
    ret
  end

  def self.get_conditions(filter)
    filter = filters.tr('*', '%')
    ret = {}
    unless filter.nil?
      ret[:qry] = 'title LIKE :v_filter or description LIKE :v_filter '
      ret[:values] = { v_filter: filter }
    end
    ret
    # conditions = ["title LIKE ? or description LIKE ? "
  end

  def others
    Role.all
  end

  def is_admin?
    admin = Role.find_by_name('admin')
    is_child_of? admin
  end

  def is_cots?
    cots = Role.find_by_name('cots')
    is_child_of? cots
  end
end
