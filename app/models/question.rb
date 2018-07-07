# frozen_string_literal: true

class Question < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon

  validates_presence_of :question

  attr_accessor :user
  attr_accessible :id, :question, :answer, :position, :asker_id, :responder_id, :domain

  belongs_to :asker,
             class_name: 'User'

  belongs_to :responder,
             class_name: 'User'
  #
  def user=(user)
      fname= "#{self.class.name}.#{__method__}"
    def_user(user)
    if user.nil?
      begin
        self.asker = User.find_by_login('visiteur')
      rescue Exception => e
        LOG.error(fname){ 'user visiteur non trouve:' + e.inspect}
      end
    end
    unless user.nil?
      self.asker = user
      self.responder = user if answer.present?
    end
  end

  def ident
    question
  end

  def self.get_conditions(filter)
    filter = filters.tr('*', '%')
    ret = {}
    unless filter.nil?
      ret[:qry] = "question LIKE :v_filter or answer LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
      ret[:values] = { v_filter: filter }
    end
    ret
    # conditions = ["question LIKE ? or answer LIKE ? or updated_at LIKE ?"
  end

  def update_from_params(question, user)
    self.responder = user
    update_attributes(question)
  end
end
