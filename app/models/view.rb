# frozen_string_literal: true

class View < ActiveRecord::Base
  include Models::SylrplmCommon

  attr_accessible :id, :name, :description, :domain

  validates_presence_of     :name
  validates_uniqueness_of   :name

  has_and_belongs_to_many :relations, join_table: :relations_views
  def to_s
    ret = "View(#{id}), relations=[\n"
    # rails2 relations.sort! { |a,b| a.typesobject.name <=> b.typesobject.name  }.each do |rel|
    relations.to_a.sort! { |a, b| a.typesobject.name <=> b.typesobject.name }.each do |rel|
      ret << "\t#{rel.ident}\n"
    end
    ret << ']'
    ret
  end

  def name_translate
    PlmServices.translate("view_#{name}")
  end
end
