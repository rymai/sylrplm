class Question < ActiveRecord::Base
  include Models::SylrplmCommon
  validates_presence_of :question, :answer
  
  def self.create_new()
    obj=Question.new
    obj.set_default_values( true) 
    obj
  end
  def self.get_conditions(filter)
    filter=filter.gsub("*","%")
    conditions = ["question LIKE ? or answer LIKE ? or updated_at LIKE ?",
    filter, filter, 
    filter ] unless filter.nil?
  end
  
end
