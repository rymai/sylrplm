class Contact < ActiveRecord::Base
	#pour def_user seulement
 	include Models::PlmObject
  	include Models::SylrplmCommon

	attr_accessible :firstname, :lastname, :adress, :postalcode, :town
	attr_accessible :email,:subject, :body

  	validates_presence_of  :email,:subject, :body

    belongs_to :typesobject

  def ident; email+"."+subject; end
  def designation; subject; end

  def find_contacts
    Contact.all(order: "updated_at DESC")
  end

  def self.get_conditions(filter)
    filter = filters.gsub("*","%")
    ret = {}
    unless filter.nil?
      ret[:qry] = "subject LIKE :v_filter or #{qry_type} or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
      ret[:values] = { v_filter: filter }
    end
    ret
  end
end
