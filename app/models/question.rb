class Question < ActiveRecord::Base

  validates_presence_of :question, :answer
  
  def self.createNew()
    obj=Question.new
    Sequence.set_default_values(obj, self.name, true) 
    obj
  end
  
  # for seo purposes
  #def to_param
  # "#{id}-#{question.gsub(/[^a-z0-9]+/i, '-')}".downcase
  #  
  #end
end
