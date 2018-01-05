# frozen_string_literal: true

class Sequence < ActiveRecord::Base
  include Models::SylrplmCommon

  attr_accessible :id, :value, :min, :max, :utility, :modify, :sequence, :domain

  validates_presence_of :utility, :value
  validates_uniqueness_of :utility
  #
  def ident
    "#{utility}.#{value}.mod:#{modify}.seq:#{sequence}"
  end

  def self.get_next_seq(utility)
    current = find_for(utility)
    ret = nil
    unless current.nil?
      old = current.value
      ret = current.value.next
      current.update_attribute('value', ret)
    end
    ret
  end

  def self.get_previous_seq(utility)
    current = find_for(utility)
    ret = nil
    unless current.nil?
      old = current.value
      ret = current.value.prev # n existe pas !!
      current.update_attribute('value', ret)
    end
    ret
  end

  def self.get_constants
    Module.constants.select do |constant_name|
      constant = eval constant_name
      isClass = constant.is_a? Class
      # puts 'Sequence.get_constants='+constant.to_s+' class='+isClass.to_s
      # if not constant.nil? && isClass && constant.extend? ActiveRecord::Base
    end
  end

  def self.get_all
    # rails2 find(:all, :order=>"utility")
    all.order(:utility)
  end

  def self.find_for(utility)
    # rails2 find(:first, :order=>"utility", :conditions => ["utility = '#{utility}' "])
    where("utility = '#{utility}' ").order(:utility).first
  end

  # recherche des attributs d'un modele
  def self.find_cols_for(model)
    ret = []
    get_all.each do |line|
      tokens = line.split('.')[0]
      ret << tokens[1] if tokens[0] == model
    end
    ret
  end

  # recherche d'un attribut d'un modele
  def self.find_col_for(model, col)
    ret = nil
    get_all.each do |line|
      tokens = line.utility.split('.')
      # puts "Sequence.find_col_for:#{model}.#{col}:#{tokens.inspect}"
      # puts "Sequence.find_col_for:tokens[0] '#{tokens[0]}' == '#{model.to_s}' ? #{tokens[0] == model.to_s}"
      # puts "Sequence.find_col_for:tokens[1] '#{tokens[1]}' == '#{col.to_s}' ? #{tokens[1] == col.to_s}"
      ret = line if tokens[0] == model.to_s && tokens[1] == col.to_s
    end
    # puts "Sequence.find_col_for(#{model}.#{col}):ret=#{ret}"
    ret
  end

  def self.get_conditions(_filter)
    nil
  end
end
