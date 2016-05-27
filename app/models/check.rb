require_dependency 'models/sylrplm_common'
class Check < ActiveRecord::Base
	include Models::PlmObject
	include Models::SylrplmCommon

	attr_accessor :user
	attr_accessible :id

	attr_accessible :checkobject_plmtype
	attr_accessible :checkobject_id
	attr_accessible :status
	attr_accessible :automatic
	attr_accessible :out_reason
	attr_accessible :out_user_id
	attr_accessible :out_group_id
	attr_accessible :out_date
	attr_accessible :in_reason
	attr_accessible :in_user_id
	attr_accessible :in_group_id
	attr_accessible :in_date
	attr_accessible :owner_id
	attr_accessible :projowner_id

	validates_presence_of :checkobject_plmtype, :checkobject_id, :status, :out_user, :out_date, :out_reason, :out_group

	belongs_to :out_user, :class_name => "User"
	belongs_to :in_user, :class_name => "User"
	belongs_to :out_group, :class_name => "Group"
	belongs_to :in_group, :class_name => "Group"
	belongs_to :owner, :class_name => "User"
	belongs_to :projowner, :class_name => "Project"

	before_save  :validity

	#status:
	CHECK_STATUS_OUT     = 1
	CHECK_STATUS_IN      = 2
	CHECK_STATUS_FREE    = 3
	#
	def select_status
		"<option value='1'>OUT</option><option value='2'>IN</option><option value='3'>FREE</option>"
	end

	def validity
		fname = "#{self.class.name}.#{__method__}"
		LOG.info(fname) {self.inspect}
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
			#LOG.info(fname) {"status=#{status} in_user=#{in_user} in_group=#{in_group} in_reason=#{in_reason} in_date=#{in_date} valid=#{valid}"}
		rescue Exception => e
			valid = false
			self.errors.add(:base,I18n.translate('activerecord.errors.messages.exception_validity', :model => 'check', :exception => e))
		end
		valid
	end

	#
	def ident
		"#{checkobject_plmtype}.#{checkobject_id}(#{status})"
	end

	#
	def self.get_checkout(object)
		fname = "#{self.class.name}.#{__method__}"
		#rails 2 find(:last, :conditions => ["checkobject_plmtype = ? and checkobject_id = ? and status = ?", object.modelname, object.id, CHECK_STATUS_OUT])
		where="checkobject_plmtype = '#{object.modelname}' and checkobject_id = '#{object.id}' and status = '#{CHECK_STATUS_OUT}'"
		ret=Check.where(where).to_a
		if ret.is_a?(Array)
			if ret.size==1
			ret=ret[0]
			else
				ret=nil
			end
		end
		LOG.debug(fname) {"check.get_checkout object=#{object}, where=#{where} ret=#{ret}"}
		ret
	end

	def initialize(*args)
		fname = "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"check.initialize nbargs=#{args.length}, args=#{args}"}
		super(*args)
		self.status    = CHECK_STATUS_OUT
		self.out_date  = Time.now.utc
		if args.size > 0
			unless args[0][:user].nil?
			self.set_default_values_with_next_seq
			end
		end
		user=self.owner
		self.out_user_id = user.id
		self.out_group_id= user.group_id
		self.projowner_id = user.project_id
	end

	# obsolete car fait dans initialize ci dessus
	def user_obsolete=(user)
		fname = "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"check:user=#{user}"}
		def_user(user)
		self.out_user_id = user.id
		self.out_group_id= user.group_id
		self.projowner_id = user.project_id
		LOG.debug(fname) {"check:user= self=#{self.inspect}"}
	end

	def object_to_check=(obj)
		fname= "#{self.class.name}.#{__method__}"
		self.checkobject_plmtype  = obj.modelname
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
