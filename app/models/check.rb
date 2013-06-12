require_dependency 'models/sylrplm_common'
class Check < ActiveRecord::Base
	include Models::PlmObject
	include Models::SylrplmCommon

	attr_accessor :user

	validates_presence_of :checkobject_plmtype, :checkobject_id, :status, :out_user, :out_date, :out_reason, :out_group

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
				valid = !( out_user.blank? || out_group.blank? || out_reason.blank? || out_date.blank? )
			when CHECK_STATUS_IN
				valid = !( in_user.blank? || in_group.blank? || in_reason.blank? || in_date.blank? )
			when CHECK_STATUS_FREE
				valid = !( in_user.blank? || in_group.blank? || in_reason.blank? || in_date.blank? )
			else
			valid = false
			self.errors.add(:status, I18n.translate('activerecord.errors.messages.status_not_valid'))
			end
			#LOG.info (fname) {"status=#{status} in_user=#{in_user} in_group=#{in_group} in_reason=#{in_reason} in_date=#{in_date} valid=#{valid}"}
		rescue Exception => e
			valid = false
			self.errors.add_to_base(I18n.translate('activerecord.errors.messages.exception_validity', :model => 'check', :exception => e))
		end
		valid
	end

	#
	def ident
		"#{checkobject_plmtype}.#{checkobject_id}(#{status})"
	end

	#
	def self.get_checkout(object)
		find(:last, :conditions => ["checkobject_plmtype = ? and checkobject_id = ? and status = ?", object.model_name, object.id, CHECK_STATUS_OUT])
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
		#LOG.info (fname) {"obj=#{obj}"}
		self.checkobject_plmtype  = obj.model_name
		self.checkobject_id = obj.id
	end

	def checkIn(params, user)
		self.attributes = params
		self.status = CHECK_STATUS_IN
		self.in_user = user
		self.in_group = user.group
		self.projowner = user.project
		self.in_date = Time.now.utc
		self
	end

	def checkFree(params, user)
		self.attributes = params
		self.status = CHECK_STATUS_FREE
		self.in_user = user
		self.in_group = user.group
		self.projowner = user.project
		self.in_date = Time.now.utc
	end

	def self.get_conditions(filter)
		nil
	end

end
