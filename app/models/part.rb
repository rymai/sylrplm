#require 'lib/models/plm_object'
require 'openwfe/representations'
require 'ruote/part/local_participant'

class Part < ActiveRecord::Base
	include Ruote::LocalParticipant
	include Models::PlmObject
	include Models::SylrplmCommon

	validates_presence_of :ident, :designation
	validates_uniqueness_of :ident, :scope => :revision

	attr_accessor :user, :link_attributes

	has_many :datafiles, :dependent => :destroy

	has_many :thumbnails,
  	:class_name => "Datafile",
  	:conditions => "typesobject_id = (select id from typesobjects as t where t.name='thumbnail')"

	belongs_to :typesobject
	belongs_to :statusobject
	belongs_to :next_status, :class_name => "Statusobject"
	belongs_to :previous_status, :class_name => "Statusobject"
	belongs_to :owner,
  :class_name => "User"
	belongs_to :group
	belongs_to :projowner,
    :class_name => "Project"
	#
	#has_and_belongs_to_many :documents, :join_table => "links",
	#:foreign_key => "father_id", :association_foreign_key => "child_id", :conditions => ["father_type='part' AND child_type='document'"]

	has_many :links_prd_effectivities,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => ["father_plmtype='part' and child_plmtype='part' and father_typesobject_id in (select id from typesobjects where name='PRD') and child_typesobject_id in (select id from typesobjects where name='EFF')"]
	has_many :prd_effectivities ,
    :through => :links_prd_effectivities,
    :source => :part

	has_many :links_var_effectivities,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => ["father_plmtype='part' and child_plmtype='part' and father_typesobject_id in (select id from typesobjects where name='VAR') and child_typesobject_id in (select id from typesobjects where name='EFF')"]
	has_many :var_effectivities ,
    :through => :links_var_effectivities,
    :source => :part


has_many :links_documents,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => { father_plmtype: 'document', child_plmtype: 'document' }
	has_many :documents,
    :through => :links_documents,
    :source => :document

	has_many :links_parts,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => { father_plmtype: 'part', child_plmtype: 'part' }
	has_many :parts ,
    :through => :links_parts,
    :source => :part

	has_many :links_parts_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => { father_plmtype: 'part', child_plmtype: 'part' }
	has_many :parts_up ,
    :through => :links_parts_up,
    :source => :part_up

	has_many :links_projects_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => ["father_plmtype='project' and child_plmtype='part'"]
	has_many :projects_up ,
    :through => :links_projects_up,
    :source => :project_up

	has_many :links_customers_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => ["father_plmtype='customer' and child_plmtype='part'"]
	has_many :customers_up ,
    :through => :links_customers_up,
    :source => :customer_up
	#
	#def to_s
	#	self.ident+"/"+self.revision+"-"+self.designation+"-"+self.typesobject.name+"-"+self.statusobject.name
	#end
	def user=(user)
		def_user(user)
	end

	# modifie les attributs avant edition
	def self.find_edit(object_id)
		obj=find(object_id)
		obj.edit
		obj
	end

	def self.get_types_part
		Typesobject.find(:all, :order=>"name",
		:conditions => ["forobject = 'part'"])
	end

	def self.get_conditions(filter)
		filter = filter.gsub("*","%")
		ret={}
		unless filter.nil?
			ret[:qry] = "ident LIKE :v_filter or revision LIKE :v_filter or designation LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter or "+qry_type+" or "+qry_status+
			" or "+qry_owner_id
			ret[:values]={:v_filter => filter}
		end
		ret
	#conditions = ["ident LIKE ? or "+qry_type+" or revision LIKE ? or designation LIKE ? or "+qry_status+
	#  " or "+qry_owner+" or date LIKE ? "
	end

	def relations
		Relation.relations_for(self)
	end

	def variants
		fname= "#{self.class.name}.#{__method__}"
		ret=[]
		parts.each do |part|
			if part.typesobject.name == "VAR"
				LOG.info (fname){"part:#{part}"}
			ret << part
			end
		end
		ret
	end

	def users
		nil
	end
	#
	# this object could have a 3d or 2d model show in tree
	#
	def have_model_design?
			true
	end
end
