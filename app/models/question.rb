class Question < ActiveRecord::Base
  include Models::SylrplmCommon
  validates_presence_of :question

  belongs_to :asker,
  :class_name => "User"

  belongs_to :responder,
  :class_name => "User"
  def self.create_new(params, user)
    #puts "create_new:"+params.inspect
    unless params.nil?
      obj=Question.new(params)
    else
      obj=Question.new
    end
    obj.set_default_values( true)
    if user.nil?
      begin
        user=User.find_by_login("visiteur")
      rescue Exception => e
        puts "user visiteur non trouve:"+e.inspect
      end
    end
    unless user.nil?
      obj.asker=user
      unless obj.answer.nil?
        obj.responder=user
      end
    else
      obj=nil
    end
    #puts "create_new:"+obj.inspect
    obj
  end

  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "question LIKE :v_filter or answer LIKE :v_filter or updated_at LIKE :v_filter"
      ret[:values]={:v_filter => filter}
    end
    ret
  #conditions = ["question LIKE ? or answer LIKE ? or updated_at LIKE ?"
  end

  def update_from_params(question, user)
    #puts "question.update:"+question.inspect
    self.responder=user
    self.update_attributes(question)
  end

end
