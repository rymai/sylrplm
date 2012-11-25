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

	validates_presence_of :object, :name, :rank

	has_many :documents
	has_many :parts
	has_many :projects
	has_many :customers
	has_many :forums

	named_scope :order_default, :order=>"object,rank,name ASC"
	named_scope :order_desc, :order=>"object,rank,name DESC"
	named_scope :cond_object, lambda{|obj| {:conditions=> ["object = ?",obj] }}
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
	# argum:
	#

	def self.find_for(object, choice = 1)
		fname="#{self.class.name}.#{__method__}"
		unless object.is_a?(String)
			#object est un objet
			stat_cur = object.statusobject
			LOG.info(fname){"choice(#{choice}),promote_id(#{stat_cur.promote_id}),demote_id(#{stat_cur.demote_id})"}
			#cond="object = '#{object.model_name}' && ((demote_id = #{choice} && rank <= #{stat_cur.rank}) || (promote_id = #{choice} && rank >= #{stat_cur.rank})) "
			cond_object="object = '#{object.model_name}'"
			cond_promote="rank >= #{stat_cur.rank}" if stat_cur.promote_id == choice
			cond_demote="rank <= #{stat_cur.rank}" if stat_cur.demote_id == choice
			if !cond_promote.nil? &&  !cond_demote.nil?
				cond_="(#{cond_promote} || #{cond_demote})"
			else
				unless cond_promote.nil?
				cond_=cond_promote
				else
				cond_=cond_demote
				end
			end
			unless cond_.nil?
				cond="#{cond_object} && (#{cond_}) "
			end
		else
		# object est une string
			cond="object = '#{object}'"
		end
		LOG.info(fname){"choice(#{choice})=>cond_promote(#{cond_promote}),cond_demote(#{cond_demote}),cond(#{cond})"}
		Statusobject.order_default.find(:all, :conditions => [cond]) unless cond.nil?
	end

	#
	def self.get_first(object)
		#order_desc.find(:first, :order=>"object,rank ASC",  :conditions => ["object = '#{object}'"])
		Statusobject.find_by_object(object)
	end

	def self.get_last(object)
		#find(:first, :order=>"object,rank DESC",  :conditions => ["object = '#{object}'"])
		#order_default.cond_object(object).last
		order_default.find_last_by_object(object)
	end

	def get_previous
		if(rank > Statusobject.get_first(object).rank)
			new_rank=current_status.rank-1
			Statusobject.find(:first, :conditions => ["object = '#{object}' && rank=#{new_rank}"])
		else
			current_status
		end
	end

	def get_next
		if(rank < Statusobject.get_last(object).rank)
			new_rank = rank + 1
			Statusobject.find(:first, :conditions => ["object = '#{object}' && rank=#{new_rank}"])
		else
		self
		end
	end

	def self.find_next(object, current_status)
		if(current_status.rank < get_last(object).rank)
			new_rank=current_status.rank+1
			find(:first, :conditions => ["object = '#{object}' && rank=#{new_rank}"])
		else
		current_status
		end
	end

	def self.find_previous(object, current_status)
		if(rank > get_first(object).rank)
			new_rank = rank-1
			find(:first, :conditions => ["object = '#{object}' && rank=#{new_rank}"])
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
		"#{object}.#{name}"
	end
end
