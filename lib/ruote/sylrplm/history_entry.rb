require 'openwfe/extras/expool/db_history'

module Ruote
	module Sylrplm
		class HistoryEntry < OpenWFE::Extras::HistoryEntry
			#include Models::PlmObject
			include Models::SylrplmCommon

			#rails2 has_many :links_customers, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='history_entry' and child_plmtype='customer'"]
			has_many :links_customers, -> { where(father_plmtype: 'history_entry'  , child_plmtype: 'customer') }, :class_name => "Link", :foreign_key => "child_id"

			has_many :customers , :through => :links_customers, :source => :customer_down

			#rails2 has_many :links_documents, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='history_entry' and child_plmtype='document'"]
			has_many :links_documents, -> { where(father_plmtype: 'history_entry'  , child_plmtype: 'document') }, :class_name => "Link", :foreign_key => "child_id"

			has_many :documents , :through => :links_documents, :source => :document_down

			#rails2 has_many :links_parts, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='history_entry' and child_plmtype='part'"]
			has_many :links_parts, -> { where(father_plmtype: 'history_entry'  , child_plmtype: 'part') }, :class_name => "Link", :foreign_key => "child_id"
			has_many :parts , :through => :links_parts, :source => :part_down

			#rails2 has_many :links_projects, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='history_entry' and child_plmtype='project'"]
			has_many :links_projects, -> { where(father_plmtype: 'history_entry'  , child_plmtype: 'project') }, :class_name => "Link", :foreign_key => "child_id"

			has_many :projects , :through => :links_projects, :source => :project_down

			#rails2 has_many :links_plmobjects, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='history_entry'"]
			has_many :links_plmobjects, -> { where(father_plmtype: 'history_entry' ) }, :class_name => "Link", :foreign_key => "child_id"

			attr_accessor :link_attributes

			def plm_objects
				fname= "#{self.class.name}.#{__method__}"
				ret=[]
				#self.links_plmobjects.each do |lnk|
				cond = "father_plmtype='history_entry' and father_id = '#{self.id}'"
				lnks = Link.find(:all, :conditions => [cond])
				#LOG.debug (fname){"cond=#{cond} #{lnks.count} link trouves"}
				lnks.each  do |lnk|
					#LOG.debug (fname){"lnk=#{lnk} father=#{lnk.father.ident} child=#{lnk.child.ident}"}
					ret.push lnk.child unless lnk.child.nil?
				end
				ret
			end

			def link_attributes=(att)
				fname= "#{self.class.name}.#{__method__}"
				@link_attributes = att
				#LOG.debug (fname){"HistoryEntry:link_attributes=#{@link_attributes}"}
				@link_attributes
			end

			def link_attributes
				@link_attributes
			end

			def typesobject
				Typesobject.find_by_forobject(model_name)
			end

			def model_name
				HistoryEntry.model_name
			end

			def self.model_name
				"history_entry"
			end

			def ident
				#fei.to_s+"_"+wfid.to_s+"_"+wfname.to_s
				[wfid, wfname].join("_")
			end

			def cancel?
				source=='expool' && event=='cancel'
			end

		end
	end

end
