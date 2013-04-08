#require 'lib/models/plm_object'
class Project < ActiveRecord::Base
	include Models::PlmObject
	include Models::SylrplmCommon
	validates_presence_of :ident, :designation
	validates_uniqueness_of :ident

	attr_accessor :user, :link_attributes

  has_many :datafiles, :dependent => :destroy
  has_many :thumbnails, 
  	:class_name => "Datafile", 
  	:conditions => "typesobject_id = (select id from typesobjects as t where t.name='#{::SYLRPLM::TYPE_DATAFILE_THUMBNAIL}')"

	belongs_to :typesobject
	belongs_to :typeaccess,
  :class_name => "Typesobject"
	belongs_to :statusobject
	belongs_to :owner, :class_name => "User"
	belongs_to :group

	has_and_belongs_to_many :users

	#has_many :projects_users, :dependent => :delete_all
	#has_many :users, :through => :projects_users

	has_many :links_documents,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => ["father_plmtype='project' and child_plmtype='document'"]
	has_many :documents ,
    :through => :links_documents

	has_many :links_parts,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => ["father_plmtype='project' and child_plmtype='part'"]
	has_many :parts ,
    :through => :links_parts

	has_many :links_customers_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => ["father_plmtype='customer' and child_plmtype='project'"]
	has_many :customers_up ,
    :through => :links_customers_up,
    :source => :customer_up
	

	def user=(user)
		def_user(user)
	end

	# renvoie le nom du projet affecte par defaut au user
	def for_user(username)
		::SYLRPLM::USER_PROJECT_IDENT+username
	end

	# modifie les attributs avant edition
	def self.find_edit(object_id)
		obj=find(object_id)
		obj.edit
		obj
	end

	def self.get_types_project
		Typesobject.find(:all, :order=>"name",
		:conditions => ["forobject = 'project'"])
	end

	def add_parts_from_favori(favori)
		favori.items.each do |item|
			parts << item
		end
	end

	def remove_parts()
		parts =nil
	end

	def remove_part(item)
		parts.delete(item)
	end

	def self.get_conditions(filter)
		filter = filters.gsub("*","%")
		ret={}
		unless filter.nil?
			ret[:qry] = "ident LIKE :v_filter or "+qry_type+" or designation LIKE :v_filter or "+qry_status+
			" or "+qry_owner+" or date LIKE :v_filter "
			ret[:values]={:v_filter => filter}
		end
		ret
	#conditions = ["ident LIKE ? or "+qry_type+" or designation LIKE ? or "+qry_status+
	#  " or "+qry_owner+" or date LIKE ? "
	end

	def variants
		nil
	end
end
