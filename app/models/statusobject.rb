#  ==========
#  = Banner =
#  ==========
#
#  statusobject.rb
#  sylrplm
#
#  Created by Sylvère on 2012-02-02.
#  Copyright 2012 Sylvère. All rights reserved.
#
class Statusobject < ActiveRecord::Base
	include Models::SylrplmCommon

	validates_presence_of :forobject, :name, :rank
	validates_uniqueness_of :name, :scope => :forobject, :scope => :rank

	has_many :documents
	has_many :parts
	has_many :projects
	has_many :customers
	has_many :forums

	has_many :documents, :foreign_key => :next_status
	has_many :parts, :foreign_key => :next_status
	has_many :projects, :foreign_key => :next_status
	has_many :customers, :foreign_key => :next_status
	has_many :forums, :foreign_key => :next_status

	has_many :documents, :foreign_key => :previous_status
	has_many :parts, :foreign_key => :previous_status
	has_many :projects, :foreign_key => :previous_status
	has_many :customers, :foreign_key => :previous_status
	has_many :forums, :foreign_key => :previous_status

	belongs_to  :typesobject

	has_and_belongs_to_many :next_statusobjects, :join_table => "statusobjects_nexts", :class_name => "Statusobject", :foreign_key => "other_statusobject_id"
	has_and_belongs_to_many :previous_statusobjects, :join_table => "statusobjects_previous", :class_name => "Statusobject", :foreign_key => "other_statusobject_id"

	named_scope :order_default, :order => "forobject,rank,name ASC"
	named_scope :order_desc, :order => "forobject,rank,name DESC"
	named_scope :cond_object, lambda{|obj| {:conditions=> ["forobject = ?",obj] }}
	named_scope :find_all , order_default.all

	PREFIX_PROMOTE="status_promote_"
	PREFIX_DEMOTE="status_demote_"
	PREFIX_REVISE="status_revise_"
	#
	def initialize(*args)
		super
		fname="#{self.class.name}.#{__method__}"
		LOG.info(fname){"args=#{args} #{args.size}"}
		self.attribute_names.each do |strcol|
			LOG.info(fname){"col:#{strcol}"}
		end
		self[:rank] = 1
		self[:forobject] = "document"

		if (self.respond_to? :typesobject)
			if args.size==0 || (args.size>0 && (!args[0].include?(:typesobject)))
				self[:typesobject] = ::Typesobject.find_for(self.forobject).first
			end
		end

		if args.size>0
			unless args[0][:user].nil?
			self.set_default_values_with_next_seq
			end
		end
	end

	def name_translate
		PlmServices.translate("typesobject_name_#{name}")
	end

	def forobject_translate
		PlmServices.translate("forobject_#{forobject}")
	end

	def promote
		promote_id.to_s+":"+I18n.t(PREFIX_PROMOTE+promote_id.to_s)
	end

	def demote
		demote_id.to_s+":"+I18n.t(PREFIX_DEMOTE+demote_id.to_s)
	end

	def revise
		revise_id.to_s+":"+I18n.t(PREFIX_REVISE+revise_id.to_s)
	end

	def self.promote_choice
		# 0:forbidden
		# 1:promote_by_select
		# 2:promote by menu
		# 3:promote by action
		[0,1,2,3].collect { |num| [I18n.t(PREFIX_PROMOTE+num.to_s), num]}
	end

	def self.demote_choice
		[0,1,2,3].collect { |num| [I18n.t(PREFIX_DEMOTE+num.to_s), num]}
	end

	def self.revise_choice
		# 0:no revision
		# 1:revise by menu
		# 2:revise by action
		[0,1,2].collect { |num| [I18n.t(PREFIX_REVISE+num.to_s), num]}
	end

	def self.get_objects_with_status
		ret=["document", "part", "project", "customer", "forum"]
	end

	def get_others_status
		any_type = ::Typesobject.find_by_forobject_and_name(self.forobject, PlmServices.get_property(:TYPE_GENERIC))
		objtype = self.typesobject
		objtype = any_type if self.typesobject.nil?
		cond = ""
		cond << "id <> #{self.id} and " unless self.id.nil?
		##cond << " forobject = '#{self.forobject}' and (typesobject_id=#{objtype.id} or typesobject_id=#{any_type.id} or typesobject_id is null)"
		cond << " forobject = '#{self.forobject}' and (typesobject_id=#{objtype.id} or typesobject_id is null)"
		#puts "get_others_status:objtype=#{objtype} any_type=#{any_type} cond=#{cond}"
		ret=Statusobject.order_default.find(:all, :conditions => [cond]).each  do |status|
			status.name = status.name_translate
		end
		ret
	end
	#
	# recherche des status possibles pour un type d'objet et un contexte donné
	# argum: object String ou classe plm
	# argum: choice type de promote ou demote recherche
	#  - 1 libre
	#  - 2 par le menu
	#  - 3 par action
	#  - 0 interdit
	#
	def self.find_for(object, choice = 1)
		fname="#{self.class.name}.#{__method__}"
		unless object.is_a?(String)
			#object est un objet
			stat_cur = object.statusobject
			unless stat_cur.nil?
				LOG.info(fname){"choice(#{choice}),promote_id(#{stat_cur.promote_id}),demote_id(#{stat_cur.demote_id})"}
				#cond="object = '#{object.model_name}' && ((demote_id = #{choice} && rank <= #{stat_cur.rank}) || (promote_id = #{choice} && rank >= #{stat_cur.rank})) "
				cond_object="forobject = '#{object.model_name}'"
				cond_promote="rank >= #{stat_cur.rank}" if stat_cur.promote_id == choice
				cond_demote="rank <= #{stat_cur.rank}" if stat_cur.demote_id == choice
				if !cond_promote.nil? &&  !cond_demote.nil?
					#LOG.info(fname){"!cond_promote.nil? &&  !cond_demote.nil?"}
					cond_="(#{cond_promote} or #{cond_demote})"
				else
					unless cond_promote.nil?
					cond_=cond_promote
					else
					cond_=cond_demote
					end
				end
				unless cond_.nil?
					cond="#{cond_object} and (#{cond_}) "
				end
			else
				LOG.error (fname) {"DATABASE_CONSISTENCY_ERROR: no status for #{object.ident}"}
			end
		else
		# object est une string
			cond="forobject = '#{object}'"
		end
		#LOG.debug (fname) {"cond= #{cond}"}
		ret = Statusobject.order_default.find(:all, :conditions => [cond]) unless cond.nil?
		#LOG.debug(fname){"stat_cur=#{stat_cur} choice(#{choice})=>cond_promote(#{cond_promote}),cond_demote(#{cond_demote}),cond(#{cond}) ret=#{ret}"}
		ret.each  do |status|
			status.name = status.name_translate
		end
		ret
	end

	#
	def self.get_first(obj)
		fname="#{self.class.name}.#{__method__}"
		any_type=::Typesobject.find_by_forobject_and_name(obj.model_name, PlmServices.get_property(:TYPE_GENERIC))
		any_type=::Typesobject.find_by_name(PlmServices.get_property(:TYPE_GENERIC)) if any_type.nil?
		if obj.respond_to? :typesobject
		objtype = obj.typesobject
		else
		objtype = any_type
		end
		#LOG.debug(fname){"obj=#{obj} objtype=#{objtype} any_type=#{any_type}"}
		cond="forobject='#{obj.model_name}' and (typesobject_id=#{objtype.id} or typesobject_id=#{any_type.id} or typesobject_id is null)"
		ret=Statusobject.order_default.find(:first, :conditions => [cond])
		#LOG.info(fname){"status.get_first:cond=#{cond} : #{ret}"}
		ret
	end

	def self.get_last(obj)
		any_type=::Typesobject.find_by_forobject_and_name(obj.model_name, PlmServices.get_property(:TYPE_GENERIC))
		any_type=::Typesobject.find_by_name(PlmServices.get_property(:TYPE_GENERIC)) if any_type.nil?
		obj.typesobject=any_type if obj.typesobject.nil?
		cond="forobject='#{obj.model_name}' and (typesobject_id=#{obj.typesobject_id} or typesobject_id= #{any_type.id} or typesobject_id is null)"
		ret=Statusobject.order_default.find(:last, :conditions => [cond])
		#puts "cond=#{cond} get_last:#{ret}"
		ret
	end

	def self.get_conditions(filter)
		filter = filters.gsub("*","%")
		ret={}
		unless filter.nil?
			ret[:qry] = "object LIKE :v_filter or name LIKE :v_filter or description LIKE :v_filter or rank LIKE :v_filter or promote LIKE :v_filter or demote LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
			ret[:values]={:v_filter => filter}
		end
		ret
	#conditions = ["object LIKE ? or name LIKE ? or description LIKE ? or rank LIKE ? or promote LIKE ? or demote LIKE ? ",
	end

	def ident
		"#{forobject}.#{name}"
	end
end
