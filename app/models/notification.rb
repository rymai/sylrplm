#
#  notification.rb
#  sylrplm
#
#  Created by Sylvère on 2012-02-04.
#  Copyright 2012 Sylvère. All rights reserved.
#
require 'link'
require 'models/plm_object'
require 'models/sylrplm_common'

class Notification < ActiveRecord::Base
	# pour def_user
	include Models::PlmObject
	#pour get_controller_from_model_type
	include Models::SylrplmCommon
	validates_presence_of :forobject_type, :forobject_id,  :event_date, :event_type
	belongs_to :responsible,
  :class_name => "User"
	#
	def initialize(*args)
		super
		unless args[0][:user].nil?
		self.set_default_values_with_next_seq
		end
	end

	def user=(user)
		def_user(user)
	end

	def ident
		"#{forobject_type}.#{forobject_id}.#{responsible.login}.#{event_type}"
	end

	def init_mdd
		create_table "notifications", :force => true do |t|
			t.string   "forobject_type"
			t.integer  "forobject_id"
			t.date     "event_date"
			t.text     "event_type"
			t.integer  "responsible_id"
			t.date     "notify_date"
			t.datetime "created_at"
			t.datetime "updated_at"
		end
	end

	# utilisation:
	# ruby script/console
	# Notification.notify

	def notify_me
		Notification.notify_all(self)
	end

	def path
		name=self.class.name+"."+__method__.to_s+":"
		#p get_controller_from_model_type("document")
		obj=object
		unless obj.nil?
			ret=obj.follow_up(nil)
		else
		ret=[]
		end
		puts name+" branches:"
		ret.each do |path|
			puts path
		end
		ret
	end

	def object
		name=self.class.name+"."+__method__.to_s+":"
		ret=get_object(self.forobject_type, self.forobject_id)
		#puts name +" object="+ret.inspect
		ret
	end

	def to_s
		id.to_s+" "+event_type+" "+forobject_type+":"+forobject_id.to_s+" at "+event_date.to_s+" by "+responsible.login+" => "+notify_date.to_s
	end

	def self.get_conditions(filter)
		filter = filter.gsub("*","%")
		ret = {}
		if filter.present?
			ret[:qry] = "forobject_type LIKE :v_filter or notify_users LIKE :v_filter or #{qry_responsible_id} or #{qrys_object_ident} or event_type LIKE :v_filter or to_char(event_date, 'YYYY/MM/DD')  LIKE :v_filter or to_char(notify_date, 'YYYY/MM/DD') LIKE :v_filter"
			ret[:values] = { v_filter: filter }
		end
		ret
	end
	# loop on user

	def self.notify_all(id)
		fname = "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"id=#{id}"}
		from = User.find_by_login(::SYLRPLM::USER_ADMIN)
		ret=[]
		# all notifications send for all users
		to_notify_all=[]
		#
		# loop on users with a valid email
		#
		User.find_with_mail.each do |user|
			LOG.debug (fname) {"*** user=#{user} subscription=#{user.subscription}"}
			to_notify = notify_user(user, id)
			#
			# send notifications for the user
			msg = send_notifications(to_notify, from, user)
			if msg == :mail_delivered
				to_notify.each do |tonotif, notify|
					unless to_notify_all.include? tonotif
						to_notify_all << tonotif
						tonotif.update_attributes({:notify_date => Time.now})
					end
				end
				ret << { :user => user, :count => to_notify.count }
			end
		end
		#to_notify_all.each do |notif|
		#	notif.update_attributes({:notify_date => Time.now})
		#end
		ret.each do |nnn|
			LOG.debug (fname){"user=#{nnn[:user]} cnt=#{nnn[:count]} msg=#{nnn[:msg]}"}
		end
		ret
	end

	def self.notify_user(user, id=nil)
		fname = "#{self.class.name}.#{__method__}"
		#
		# loop of subscriptions of the user
		#
		#user.subscriptions.each do |subscription|
		# notifications to send to the user
		to_notify = notify_for_subscription(id, user.subscription)
		#end
		to_notify
	end

	def self.notify_for_subscription(id, subscription)
		fname = "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"	*** subscription=#{subscription}"}
		# notifications to send to the user
		to_notify  = Hash.new
		unless subscription.nil?
			inproject = subscription.inproject_array
			ingroup = subscription.ingroup_array
			#LOG.debug (fname) {"subscription.ingroup=#{ingroup}"}
			#LOG.debug (fname) {"subscription.inproject=#{inproject}"}
			# all notifications for the user
			the_notifs = Hash.new
			subscription.fortypesobject.each do |fortype|
			#
			# search for active notification (not yet notify)
			#
				if id.nil? || id == "all"
					notifs = self.find(:all, :conditions => ["notify_date is null and forobject_type = '#{fortype.forobject}'"])
				else
					notifs = Notification.find(id)
				end
				if notifs.is_a?(Array)
					notifs.each do |notif|
						the_notifs[notif] = {:to_notify => false, :notify => true} if to_notify[notif].nil?
					end
				else
				# only one notification was found
					the_notifs[notifs] = {:to_notify => false, :notify => true} if to_notify[notifs].nil?
				end
				LOG.debug (fname) {"		*** fortype=#{fortype.forobject} / #{fortype.name} : the_notifs.count=#{the_notifs.count}"}
				the_notifs.each do |notif, notify|
					LOG.debug (fname) {"			*** notif=#{notif}, notify=#{notify}"}
					# if the object is destroy, we can't retrieve group and projowner !!, then, no notif
					#LOG.debug (fname) {"type=#{notif.forobject_type} id=#{notif.forobject_id}"}
					begin
						notif_obj = ::PlmServices.get_object(notif.forobject_type, notif.forobject_id)
					rescue Exception => e
						LOG.warn (fname) {"object no more existing=#{notif.forobject_type}.#{notif.forobject_id}:#{e}"}
					end
					unless notif_obj.nil?
						if notif_obj.typesobject.name == fortype.name
							#LOG.debug (fname) {"notif=#{notif} notif_obj=#{notif_obj}"}
							LOG.debug (fname) {"subscription.ingroup=#{ingroup} include? notif_obj.group=#{notif_obj.group.name} "}
							LOG.debug (fname) {"subscription.inproject=#{inproject} include? notif_obj.projowner=#{notif_obj.projowner.ident}"} if notif_obj.respond_to? :projowner
							group_ok = ingroup.include?(notif_obj.group.name)
							LOG.debug (fname) {"group_ok=#{group_ok}"}
							if notif_obj.respond_to? :projowner
							project_ok = inproject.include?(notif_obj.projowner.ident)
							else
							project_ok = true
							end
							LOG.debug (fname) {"project_ok=#{project_ok}"}
							if group_ok || project_ok
								if to_notify[notif].nil?
									notify[:to_notify] = true
									to_notify[notif] = notify
									LOG.debug (fname) {"notif to_notify='#{notif}'"}
								else
									LOG.debug (fname) {"notif to_notify='#{notif}'  but already include"}
								end
							end
						end
					end
				end
			end
		end
		to_notify
	end

	def could_show_object?
		fname = "#{self.class.name}.#{__method__}"
		ret = !(::Plmobserver::EVENTS_DESTROY.include? (self.event_type.to_sym))
		#LOG.debug (fname){"EVENTS_DESTROY=#{::Plmobserver::EVENTS_DESTROY}:#{self.event_type}:ret=#{ret}"}
		ret
	end

	def self.send_notifications(to_notify, from, user)
		fname = "#{self.class.name}.#{__method__}"
		LOG.info(name){to_notify.count.to_s+" notification to send for "+user.login}
		txt = nil
		if to_notify.count > 0
			#puts to_notify.inspect
			notifs = {}
			recordset = []
			to_notify.each do |tonotif, notify|
			#LOG.debug (fname) {"tonotif=#{tonotif.inspect}"}
				recordset << tonotif
			end
			notifs[:recordset] = recordset

			#LOG.debug (fname){"fromuser='#{from.login}' frommail='#{from.email}' touser='#{user.login}' tomail='#{user.email}'"}
			email = PlmMailer.create_notify(notifs, from, user)
			###################
			#TODO syl test
			#email=nil
			###################
			unless email.nil?
				#LOG.debug (fname){"email avant envoi='#{email}'"}
				email.set_content_type("text/html")
				PlmMailer.deliver(email)
				#LOG.debug (fname){"email apres envoi='#{email}'"}
				cnt = to_notify.count
				msg = :mail_delivered

			else
				LOG.warn (fname) {"ctrl_mail_not_created pour #{user.login}"}
				msg = :mail_not_created
			end
			# update notification users
			recordset.each do |notif|
				LOG.warn (fname) {"notif.notify_users=#{notif.notify_users}"}
				prefixe = "#{notif.notify_users}," unless notif.notify_users.blank?
				txt = "#{prefixe}#{user.login}:#{msg}"
				notif.update_attributes({:notify_users => "#{txt}"})
			end
		else
			msg = :nothing_to_notify
		end
		msg
	end

end
