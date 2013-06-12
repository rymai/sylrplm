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

	has_many :documents
	has_many :parts
	has_many :projects
	has_many :customers
	has_many :forums

	named_scope :order_default, :order => "forobject,rank,name ASC"
	named_scope :order_desc, :order => "forobject,rank,name DESC"
	named_scope :cond_object, lambda{|obj| {:conditions=> ["forobject = ?",obj] }}
	named_scope :find_all , order_default.all

	PREFIX_PROMOTE="status_promote_"
	PREFIX_DEMOTE="status_demote_"
	def promote
		promote_id.to_s+":"+I18n.t(PREFIX_PROMOTE+promote_id.to_s)
	end

	def demote
		demote_id.to_s+":"+I18n.t(PREFIX_DEMOTE+demote_id.to_s)
	end

	def self.promote_choice
		[0,1,2,3].collect { |num| [I18n.t(PREFIX_PROMOTE+num.to_s), num]}
	end

	def self.demote_choice
		[0,1,2,3].collect { |num| [I18n.t(PREFIX_DEMOTE+num.to_s), num]}
	end

	def self.get_objects_with_status
		ret=["document", "part", "project", "customer", "forum"]
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
					LOG.info(fname){"!cond_promote.nil? &&  !cond_demote.nil?"}
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
		LOG.debug (fname) {"cond= #{cond}"}
		ret = Statusobject.order_default.find(:all, :conditions => [cond]) unless cond.nil?
		if ret.nil?
		#ret=[]
		end
		LOG.info(fname){"stat_cur=#{stat_cur} choice(#{choice})=>cond_promote(#{cond_promote}),cond_demote(#{cond_demote}),cond(#{cond}) ret=#{ret}"}
		ret

	end

	#
	def self.get_first(object)
		#order_desc.find(:first, :order=>"object,rank ASC",  :conditions => ["object = '#{object}'"])
		order_default.find_by_forobject(object)
	end

	def self.get_last(object)
		#find(:first, :order=>"object,rank DESC",  :conditions => ["object = '#{object}'"])
		#order_default.cond_object(object).last
		order_default.find_last_by_forobject(object)
	end

	def get_previous
		if(rank > get_first(forobject).rank)
			new_rank=current_status.rank-1
			Statusobject.find(:first, :conditions => ["forobject = '#{forobject}' and rank=#{new_rank}"])
		else
			current_status
		end
	end

	def get_next
		#puts "statusobject:rank=#{rank} last=#{Statusobject.get_last(forobject).rank}"
		ret=self
		if(rank < Statusobject.get_last(forobject).rank)
			new_rank = rank + 1
			cond="forobject = '#{forobject}' and rank=#{new_rank}"
			ret=Statusobject.find(:first, :conditions => [cond])
		end
		ret
	end

	def self.find_next(object, current_status)
		if(current_status.rank < Statusobject.get_last(object).rank)
			new_rank=current_status.rank+1
			find(:first, :conditions => ["forobject = '#{object}' and rank=#{new_rank}"])
		else
		current_status
		end
	end

	def self.find_previous(object, current_status)
		if(rank > get_first(object).rank)
			new_rank = rank-1
			find(:first, :conditions => ["forobject = '#{object}' and rank=#{new_rank}"])
		else
		self
		end
	end

	def self.get_conditions(filter)
		filter = filters.gsub("*","%")
		ret={}
		unless filter.nil?
			ret[:qry] = "object LIKE :v_filter or name LIKE :v_filter or description LIKE :v_filter or rank LIKE :v_filter or promote LIKE :v_filter or demote LIKE :v_filter "
			ret[:values]={:v_filter => filter}
		end
		ret
	#conditions = ["object LIKE ? or name LIKE ? or description LIKE ? or rank LIKE ? or promote LIKE ? or demote LIKE ? ",
	end

	def ident
		"#{forobject}.#{name}"
	end
end
