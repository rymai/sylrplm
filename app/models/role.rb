class Role < ActiveRecord::Base
  include Models::SylrplmCommon
  has_and_belongs_to_many :users
  validates_presence_of :title
  validates_uniqueness_of :title
  
  def self.find_by_name(name)
    find(:first , :conditions => ["title = '#{name}' "])
  end
  def self.findall_except_admin()
    find(:all , :conditions => ["title <> 'admin' "])
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
    filter=filter.gsub("*","%")
      conditions = ["title LIKE ? or description LIKE ? ",
      filter, filter] unless filter.nil?
  end
end
