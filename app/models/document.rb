class Document < ActiveRecord::Base
	include Models::PlmObject
	include Models::SylrplmCommon

	attr_accessor :link_attributes, :user

	validates_presence_of :ident , :designation
	validates_uniqueness_of :ident, :scope => :revision
	#validates_format_of :ident, :with => /^(doc|img)[0-9]+$/, :message=>" doit commencer par doc ou img suivi de chiffres"
	validates_format_of :ident, :with => /^([a-z]|[A-Z])+[0-9]+$/ #, :message=>t(:valid_ident,:typeobj =>:ctrl_document)

	belongs_to :typesobject
	belongs_to :statusobject
	belongs_to :next_status, :class_name => "Statusobject"
	belongs_to :previous_status, :class_name => "Statusobject"
	belongs_to :owner, :class_name => "User"
	belongs_to :group
	belongs_to :projowner, :class_name => "Project"

	has_many :datafiles, :dependent => :destroy

	has_many :thumbnails,
  	:class_name => "Datafile",
  	:conditions => "typesobject_id = (select id from typesobjects as t where t.name='thumbnail')"

	has_many :checks

	has_many :links_document_forum,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => { father_plmtype: 'document', child_plmtype: 'forum' }
	has_many :forums,
    :through => :links_document_forum,
    :source => :forum

	has_many :links_document_document,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => { father_plmtype: 'document', child_plmtype: 'document' }
	has_many :documents,
    :through => :links_document_document,
    :source => :document_down

	has_many :links_document_document_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => { father_plmtype: 'document', child_plmtype: 'document' }
	has_many :documents_up ,
    :through => :links_document_document_up,
    :source => :document_up

	has_many :links_part_document_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => { father_plmtype: 'part', child_plmtype: 'document' }
	has_many :parts_up,
    :through => :links_part_document_up,
    :source => :part_up

	has_many :links_project_document_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => { father_plmtype: 'project', child_plmtype: 'document' }
	has_many :projects_up,
    :through => :links_project_document_up,
    :source => :project_up

	has_many :links_customer_document_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => { father_plmtype: 'customer', child_plmtype: 'document' }
	has_many :customers_up,
    :through => :links_customer_document_up,
    :source => :customer_up

	has_many :links_history_document_up,
    :class_name => "Link",
    :foreign_key => "child_id",
    :conditions => { father_plmtype: 'history_entry', child_plmtype: 'document' }
	has_many :histories_up,
    :through => :links_history_document_up,
    :source => :history_up
    #
	def user=(user)
		def_user(user)
	end

	#essai, appelle 10 fois par document !!!
	#def after_find
	#puts "Document:after_find: ident="+ident+" type="+model_name+"."+typesobject.name+" proj="+projowner.ident+" group="+group.name
	#end

	def checkout_needed?
		true
	end

	def self.get_conditions(filters)
		filter = filters.gsub("*", "%")
		ret = {}
		unless filter.nil?
			ret[:qry] = "ident LIKE :v_filter or revision LIKE :v_filter or designation LIKE :v_filter or to_char(date, 'YYYY/MM/DD') LIKE :v_filter "
			ret[:values] = { :v_filter => filter }
		end
		ret
	end

	def self.find_all
		find(:all, :order => "ident ASC, revision ASC")
	end

	def self.find_with_part
		find(:all,
    :conditions => ["part_id IS NOT NULL"],
    :order => "ident")
	end

	def self.find_without_part
		find(:all,
    :conditions => ["part_id IS NULL"],
    :order => "ident")
	end

	def to_s
		"#{self.ident}/#{self.revision}-#{self.designation}-#{self.typesobject.try(:name)}-#{self.statusobject.try(:name)}"
	end

	def link_attributes=(att)
		@link_attributes = att
	end

	def link_attributes
		@link_attributes
	end

	# modifie les attributs avant edition
	def self.find_edit(object_id)
		obj = find(object_id)
		obj.edit
		obj
	end

	#pour par exemple interdire les fichiers dans un répertoire
	def directory?
		typesobject.name==PlmServices.get_property(:TYPE_DOC_DIRECTORY)
	end

	def get_check_out
		Check.get_checkout(self)
	end

	def can_be_check_in?(user)
		chk = get_check_out
		ret=false
		unless chk.nil?
		ret=(user==chk.out_user)
		end
		ret
	end

	def check_out(params, user)
		fname= "#{self.class.name}.#{__method__}"
		LOG.info (fname){"params=#{params}, user=#{user.inspect}"}
		ret = Check.get_checkout(self)
		if ret.nil?
			args = {}
			args[:out_reason] = params[:out_reason]
			args[:checkobject_plmtype] = self.model_name
			args[:checkobject_id] = self.id
			args[:user] = user
			ret = Check.create(args)
		end
		ret = nil if ret.errors.size>0
		ret
	end

	def check_in(params, user)
		ret = Check.get_checkout(self)
		unless ret.nil?
			ret.update_accessor(user)
			ret.checkIn(params, user)
			if ret.save
				self.update_attributes(params[:document])
			end
		end
		ret = nil if ret.errors.size>0
		ret
	end

	def check_free(params,user)
		ret = Check.get_checkout(self)
		unless ret.nil?
			ret.update_accessor(user)
			ret.checkFree(params,user)
			if ret.save
				self.update_attributes(params[:document])
			end
		end
		ret = nil if ret.errors.size>0
		ret
	end

	def checked?
		Check.get_checkout(self).present?
	end

	def variants
		nil
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
