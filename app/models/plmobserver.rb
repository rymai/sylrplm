require 'models/plm_object'
require 'models/sylrplm_common'

class Plmobserver < ActiveRecord::Observer
	#include Models::PlmObject
	include Models::SylrplmCommon
	observe :customer, :document, :part, :project
	def initialize(*args)
		super
		fname="#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"args=#{args.inspect}"}
	end

	def before_validation(object)
		name="****************"+self.class.name+"."+__method__.to_s+":"
	#puts name+object.inspect
	end

	def after_validation(object)
		name="****************"+self.class.name+"."+__method__.to_s+":"
	#puts name+object.inspect
	end

	def before_save(object)
		name="****************"+self.class.name+"."+__method__.to_s+":"
	#puts name+object.inspect
	end

	def after_save(object)
		fname="#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"object=#{object}"}
		add_notification(__method__.to_s, object)
	end

	def before_create(object)
		name="****************"+self.class.name+"."+__method__.to_s+":"
	#puts name+object.inspect

	end

	def after_create(object)
		name="****************"+self.class.name+"."+__method__.to_s+":"
		#puts name+object.inspect
		add_notification(__method__.to_s, object)
	end

	def around_create(object)
		name="****************"+self.class.name+"."+__method__.to_s+":"
	#puts name+object.inspect
	end

	def before_update(object)
		name="****************"+self.class.name+"."+__method__.to_s+":"
	#puts name+object.inspect
	end

	def after_update(object)
		name="****************"+self.class.name+"."+__method__.to_s+":"
		#puts name+object.inspect
		add_notification(__method__.to_s, object)
	end

	def around_update(object)
		name="****************"+self.class.name+"."+__method__.to_s+":"
	#puts name+object.inspect
	end

	def before_destroy(object)
		name="****************"+self.class.name+"."+__method__.to_s+":"
		#puts name+object.inspect
		add_notification(__method__.to_s, object)
	end

	def after_destroy(object)
		name="****************"+self.class.name+"."+__method__.to_s+":"
		#puts name+object.inspect
		add_notification(__method__.to_s, object)
	end

	def around_destroy(object)
		name="****************"+self.class.name+"."+__method__.to_s+":"
	#puts name+object.inspect
	end

	def add_notification(event_type, object)
		fname="****************"+self.class.name+"."+__method__.to_s+":"
		#puts fname+event_type+":"+object.inspect
		unless object.model_name == self.model_name
			params={}
			params[:forobject_type] = object.model_name
			params[:forobject_id] = object.id
			params[:event_date] = object.updated_at
			params[:event_type] = event_type
			params[:responsible] = object.owner
			Notification.create(params)
		end
	end

end
