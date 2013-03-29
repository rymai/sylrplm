require_dependency 'models/sylrplm_common'
class Check < ActiveRecord::Base
	include Models::PlmObject
	include Models::SylrplmCommon

	attr_accessor :user

	validates_presence_of :checkobject, :checkobject_id, :status, :out_user, :out_date, :out_reason, :out_group

	belongs_to :out_user, :class_name => "User"
	belongs_to :in_user, :class_name => "User"
	belongs_to :out_group, :class_name => "Group"
	belongs_to :in_group, :class_name => "Group"
	belongs_to :projowner, :class_name => "Project"

	before_save  :validity

	#status:
	CHECK_STATUS_OUT     = 1
	CHECK_STATUS_IN      = 2
	CHECK_STATUS_FREE    = 3
	#
	def validity
		fname = "#{self.class.name}.#{__method__}"
		LOG.info (fname) {self.inspect}
		valid = true
		begin
			case status
				when CHECK_STATUS_OUT
					valid = !( out_user.nil? || out_group.nil? || out_reason.nil? || out_date.nil? )
				when CHECK_STATUS_IN
				when CHECK_STATUS_FREE
				else
					valid=false
					self.errors.add(:status, I18n.translate('activerecord.errors.messages')[:status_not_valid])
			end
		rescue Exception => e
			valid = false
			msg="Exception during check validity test:"
			msg+="<br/>exception=#{e}"
			self.errors.add(msg)
		end
		valid
	end

	#
	def self.get_checkout(object)
		find(:last, :conditions => ["checkobject = ? and checkobject_id = ? and status = ?", object.model_name, object.id, CHECK_STATUS_OUT])
	end

	def initialize(*args)
		fname = "#{self.class.name}.#{__method__}"
		LOG.info (fname) {"nbargs=#{args.length}, args=#{args}"}
		super
		self.status    = CHECK_STATUS_OUT
		self.out_date  = Time.now.utc
		if args.size > 0
			unless args[0][:user].nil?
			self.set_default_values_with_next_seq
			end
		end
	end

	def user=(user)
		def_user(user)
		self.out_user = user
		self.out_group = user.group
		self.projowner = user.project
		self.out_date = Time.now.utc
	end

	def object_to_check=(obj)
		fname= "#{self.class.name}.#{__method__}"
		LOG.info (fname) {"obj=#{obj}"}
		self.checkobject  = obj.model_name
		self.checkobject_id = obj.id
	end

	def checkIn(params, user)
		self.attributes = params
		self.status = CHECK_STATUS_IN
		self.in_user = user
		self.in_group = user.group
		self.projowner = user.project
		self.in_date = Time.now.utc

		self.errors.add(:in_reason, "must be present!") if in_reason.blank?

	# if(params)
	#   # commit genere par le view
	#   params.delete("commit")
	#   params.delete("authenticity_token")
	#   params.delete("_method")
	#   params.delete("action")
	#   params.delete("controller")
	#   self.in_reason = params[:in_reason]
	# end
	end

	def checkFree(params, user)
		self.attributes = params
		self.status = CHECK_STATUS_FREE
		self.in_user = user
		self.in_date = Time.now.utc

		self.errors.add(:in_reason, "must be present!") if in_reason.blank?

	# if(params)
	#   # commit genere par le view
	#   params.delete("commit")
	#   params.delete("authenticity_token")
	#   params.delete("_method")
	#   params.delete("action")
	#   params.delete("controller")
	#   self.in_reason = params[:in_reason]
	# end
	end

	def self.get_conditions(filter)
		nil
	end

end
