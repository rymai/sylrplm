class Role < ActiveRecord::Base
  include Models::SylrplmCommon
  validates_presence_of :title
  validates_uniqueness_of :title

  has_and_belongs_to_many :users
  belongs_to :father, :class_name => "Role"
  has_many :roles, :class_name => "Role", :foreign_key => "father_id"

  def self.find_by_name(name)
    find(:first , :conditions => ["title = '#{name}' "])
  end

  def self.findall_except_admin()
    find(:all , :conditions => ["title <> 'admin' "])
  end

  def father_name
    (father ? father.title : "")
  end

  alias_method :title, :ident

  def typesobject
    Typesobject.find_by_object(model_name)
  end

  def designation
    Role.truncate_words(description, 5)
  end

  #return the list of validers
  def self.get_validers
    ret=[]
    all(:conditions => "title like 'valid%'").each do |role|
      role.users.each do |user|
        ret<<user
      end
    end
    ret
  end

  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "title LIKE :v_filter or description LIKE :v_filter "
      ret[:values]={:v_filter => filter}
    end
    ret
    #conditions = ["title LIKE ? or description LIKE ? "
  end

  def others
    Role.all
  end

end
