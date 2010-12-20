class Question < ActiveRecord::Base
  include Models::SylrplmCommon
  validates_presence_of :question, :answer
  
  def self.create_new()
    obj=Question.new
    Sequence.set_default_values(obj, self.name, true) 
    obj
  end
  def self.get_conditions(filter)
    filter=filter.gsub("*","%")
    conditions = ["question LIKE ? or answer LIKE ? or updated_at LIKE ?",
    "#{filter}", "#{filter}", 
    "#{filter}" ] unless filter.nil?
  end
  # for seo purposes
  #def to_param
  # "#{id}-#{question.gsub(/[^a-z0-9]+/i, '-')}".downcase
  #  
  #end
end
