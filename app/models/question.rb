class Question < ActiveRecord::Base
  include Models::SylrplmCommon
  validates_presence_of :question

  belongs_to :asker,
  :class_name => "User"

  belongs_to :responder,
  :class_name => "User"

  def initialize(*args)
    super
    self.set_default_values(true)
  end

  def user=(user)
    super
    if user.nil?
      begin
        self.user_id = User.find_by_login("visiteur").id
      rescue Exception => e
        puts "user visiteur non trouve:"+e.inspect
      end
    end

    unless user.nil?
      self.asker = user
      self.responder = user if self.answer.present?
    end
  end

  def self.create_new(params, user)
    raise Exception.new "Don't use this method!"
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
