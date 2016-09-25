#require 'lib/models/plm_object'
#require 'openwfe/representations'
#require 'ruote/part/local_participant'
class Part < ActiveRecord::Base
	include Ruote::LocalParticipant
	include Models::PlmObject
	include Models::SylrplmCommon

	validates_presence_of :ident, :designation
	validates_uniqueness_of :ident, :scope => :revision

	attr_accessor :user, :link_attributes
	attr_accessible :id, :owner_id, :typesobject_id, :statusobject_id, :next_status_id, :previous_status_id, :ident, :revision, :designation, :description,  :date, :owner, :group_id, :projowner_id, :domain , :type_values

	has_many :datafiles, :dependent => :destroy

	#rails2 has_many :thumbnails,  	:class_name => "Datafile",  	:conditions => "typesobject_id = (select id from typesobjects as t where t.name='thumbnail')"
	has_many :thumbnails, -> { where("typesobject_id = (select id from typesobjects as t where t.name='thumbnail')") },  	:class_name => "Datafile"

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

	#rails2 has_many :links_part_forum,    :class_name => "Link",    :foreign_key => "father_id",    :conditions => { father_plmtype: 'part', child_plmtype: 'forum' }
	has_many :links_part_forums, -> { where(father_plmtype: 'part'  , child_plmtype: 'forum') },    :class_name => "Link",    :foreign_key => "father_id"
	has_many :forums,    :through => :links_part_forums,    :source => :forum

	#rails2 has_many :links_part_documents,    :class_name => "Link",    :foreign_key => "father_id",    :conditions => { father_plmtype: 'part', child_plmtype: 'document' }
	has_many :links_part_documents, -> { where(father_plmtype: 'part'  , child_plmtype: 'document') },    :class_name => "Link",    :foreign_key => "father_id"
	has_many :documents,    :through => :links_part_documents,    :source => :document_down

	#rails2 has_many :links_part_part,    :class_name => "Link",    :foreign_key => "father_id",    :conditions => { father_plmtype: 'part', child_plmtype: 'part' }
	has_many :links_part_parts, -> { where(father_plmtype: 'part'  , child_plmtype: 'part') },    :class_name => "Link",    :foreign_key => "father_id"
	has_many :parts ,    :through => :links_part_parts,    :source => :part_down
	has_many :variants ,    :through => :links_part_parts,    :source => :variant_down
	has_many :effectivities ,    :through => :links_part_parts,    :source => :effectivity_down

	#rails2 has_many :links_part_document_up,    :class_name => "Link",    :foreign_key => "child_id",    :conditions => { father_plmtype: 'part', child_plmtype: 'document' }
	#has_many :links_part_document_up, -> { where(father_plmtype: 'part'  , child_plmtype: 'document') },    :class_name => "Link",    :foreign_key => "child_id"

	#rails2 has_many :links_part_part_up,    :class_name => "Link",    :foreign_key => "child_id",    :conditions => { father_plmtype: 'part', child_plmtype: 'part' }
	has_many :links_part_parts_up, -> { where(father_plmtype: 'part'  , child_plmtype: 'part') },    :class_name => "Link",    :foreign_key => "child_id"
	has_many :parts_up ,    :through => :links_part_parts_up,    :source => :part_up

	#rails2 has_many :links_project_part_up,    :class_name => "Link",    :foreign_key => "child_id",    :conditions => {father_plmtype: 'project', child_plmtype: 'part' }
	has_many :links_project_parts_up, -> { where(father_plmtype: 'project'  , child_plmtype: 'part') },    :class_name => "Link",    :foreign_key => "child_id"
	has_many :projects_up ,    :through => :links_project_parts_up,    :source => :project_up

	#rails2 has_many :links_customer_part_up,    :class_name => "Link",    :foreign_key => "child_id",    :conditions =>{father_plmtype: 'customer', child_plmtype: 'part' }
	has_many :links_customer_parts_up, -> { where(father_plmtype: 'customer'  , child_plmtype: 'document') },    :class_name => "Link",    :foreign_key => "child_id"
	has_many :customers_up ,    :through => :links_customer_parts_up,    :source => :customer_up
	#
	#essai
=begin
has_many :links_variant_part,
:class_name => "Link",
:foreign_key => "father_id",
:conditions => [ "father_plmtype = 'part' and child_plmtype = 'part'" ]

has_many :variant_effectivities,
:through => :links_variant_part,
:source => :effectivity_down
=end
	#
	def variant_effectivities
		fname= "#{Part}.#{__method__}"
		ret=[]
		begin
			cond="father_plmtype='part' and child_plmtype='part' and father_id = #{id}"

			#::Link.find(:all,
			#:conditions => ["father_plmtype='part' and child_plmtype='part' and father_id = #{id}"]
			::Link.all.where(cond).each do |lnk|
				father=lnk.father
				child=lnk.child
				if(father.typesobject.name == "VAR" && child.typesobject.name == "EFF")
				ret << lnk.child
				end
			end
		rescue Exception=>e
			LOG.error(fname){"ERROR finding effectivities : #{e}"}
			PlmServices.stack("variant_effectivities",20)
		end
		LOG.debug(fname){" #{ret.size} variant effectivites from #{self.ident}"}
		ret
	end

	#
	#def to_s
	#	self.ident+"/"+self.revision+"-"+self.designation+"-"+self.typesobject.name+"-"+self.statusobject.name
	#end
	def user=(user)
		def_user(user)
	end

	# modifie les attributs avant edition
	def self.find_edit(object_id)
		fname= "#{self.class.name}.#{__method__}"
		obj=find(object_id)
		obj.edit
		LOG.debug(fname) {"part find_edit :type_values=#{obj.type_values}"} if obj.respond_to? :type_values
		obj
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
