# frozen_string_literal: true

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
  # pour get_controller_from_model_type
  include Models::SylrplmCommon

  attr_accessible :id, :forobject_type, :forobject_id, :responsible_id, :event_type, :event_date, :notify_date
  attr_accessible :notify_users

  validates_presence_of :forobject_type, :forobject_id, :event_date, :event_type
  belongs_to :responsible,
             class_name: 'User'
  #
  def initialize(*args)
    super
    set_default_values_with_next_seq unless args[0][:user].nil?
  end

  def user=(user)
    def_user(user)
  end

  def ident
    ret="#{forobject_type}.#{forobject_id}.#{event_type}"
    ret+=".#{responsible.login}" unless responsible.nil?
  end

  def init_mdd
    create_table 'notifications', force: true do |t|
      t.string   'forobject_type'
      t.integer  'forobject_id'
      t.date     'event_date'
      t.text     'event_type'
      t.integer  'responsible_id'
      t.date     'notify_date'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end
  end

  # utilisation:
  # ruby script/console
  # Notification.notify

  def notify_me
    Notification.notify_all(id)
  end

  def path
    name = "#{self.class.name}.#{__method__}" + ':'
    # p get_controller_from_model_type("document")
    obj = object
    ret = if obj.nil?
            []
          else
            obj.follow_up(nil)
          end
    ret
  end

  def object
    name = "#{self.class.name}.#{__method__}" + ':'
    ret = get_object(forobject_type, forobject_id)
    ret
  end

  def to_s
    login = if responsible.nil?
              'unknown'
            else
              responsible.login
            end
    "#{id} #{event_type} #{forobject_type}:#{forobject_id} at #{event_date} by #{login} => #{notify_date}"
  end

  def self.get_conditions(filter)
    filter = filter.tr('*', '%')
    ret = {}
    if filter.present?
      ret[:qry] = "forobject_type LIKE :v_filter or notify_users LIKE :v_filter or #{qry_responsible_id} or #{qry_object_ident} or event_type LIKE :v_filter or to_char(event_date, 'YYYY/MM/DD')  LIKE :v_filter or to_char(notify_date, 'YYYY/MM/DD') LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
      ret[:values] = { v_filter: filter }
    end
    ret
  end
  # loop on user

  def self.notify_all(id)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "begin id=#{id}" }
    from = User.find_by_login(PlmServices.get_property(:USER_ADMIN))
    ret = []
    # all notifications send for all users
    to_notify_all = []
    #
    # loop on users with a valid email
    #
    User.find_with_mail.each do |user|
      LOG.debug(fname) { "***** user=#{user} subscription=#{user.subscription}" }
      to_notify = notify_user(user, id)
      #
      # send notifications for the user
      msg = send_notifications(to_notify, from, user)
      LOG.debug(fname) { "***** msg=#{msg}" }
      next unless msg == :mail_delivered
      to_notify.each do |tonotif, _notify|
        unless to_notify_all.include? tonotif
          to_notify_all << tonotif
          tonotif.update_attributes(notify_date: Time.now)
        end
      end
      ret << { user: user, count: to_notify.count }
    end
    # to_notify_all.each do |notif|
    #	notif.update_attributes({:notify_date => Time.now})
    # end
    ret.each do |nnn|
      LOG.debug(fname) { "id=#{id} ret:user=#{nnn[:user]} subscription=#{nnn[:user].subscription} cnt=#{nnn[:count]} msg=#{nnn[:msg]}" }
    end
    LOG.debug(fname) { "end id=#{id} " }
    ret
  end

  def self.notify_user(user, id = nil)
    fname = "#{self.class.name}.#{__method__}"
    #
    # loop of subscriptions of the user
    #
    # user.subscriptions.each do |subscription|
    # notifications to send to the user
    LOG.debug(fname) { "	***** user=#{user}, id=#{id}, user.subscription=#{user.subscription}" }
    to_notify = notify_for_subscription(id, user.subscription)
    LOG.debug(fname) { "	***** user=#{user}, id=#{id}" }
    LOG.debug(fname) { "	***** to_notify=#{to_notify.size}" }
    # end
    to_notify
  end

  def self.notify_for_subscription(id, subscription)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "	***** id=#{id} , subscription=#{subscription}" }
    # notifications to send to the user
    to_notify = {}
    unless subscription.nil?
      inproject = subscription.inproject_array
      ingroup = subscription.ingroup_array
      LOG.debug(fname) { "subscription.ingroup=#{ingroup}" }
      LOG.debug(fname) { "subscription.inproject=#{inproject}" }
      # all notifications for the user
      the_notifs = {}
      subscription.fortypesobject.each do |fortype|
        #
        # search for active notification (not yet notify)
        #
        if id.nil? || id == 'all'
          # rails2 notifs = self.find(:all, :conditions => ["notify_date is null and forobject_type = '#{fortype.forobject}'"])
          notifs = all.where("notify_date is null and forobject_type = '#{fortype.forobject}'").to_a
        else
          notifs = Notification.find(id).to_a
        end
        if notifs.is_a?(Array)
          notifs.each do |notif|
            the_notifs[notif] = { to_notify: false, notify: true } if to_notify[notif].nil?
          end
        else
          # only one notification was found
          the_notifs[notifs] = { to_notify: false, notify: true } if to_notify[notifs].nil?
        end
        LOG.debug(fname) { "***** fortype=#{fortype.forobject} / #{fortype.name} : the_notifs.count=#{the_notifs.count}" }
        the_notifs.each do |notif, notify|
          # notif=ActiveRecord::Relation []
          # nil notif=notif[0]
          # nil notif=notif.to_a[0]
          LOG.debug(fname) { "***** notification=#{notif.inspect}, notify=#{notify}" }
          # if the object is destroy, we can't retrieve group and projowner !!, then, no notif
          LOG.debug(fname) { "type=#{notif.forobject_type} id=#{notif.forobject_id}" }
          begin
            notif_obj = ::PlmServices.get_object(notif.forobject_type, notif.forobject_id)
          rescue Exception => e
            LOG.error(fname) { "notification no more existing=#{notif}:#{e}" }
          end
          next if notif_obj.nil?
          next unless notif_obj.typesobject.name == fortype.name
          # LOG.debug(fname) {"notif=#{notif} notif_obj=#{notif_obj}"}
          # LOG.debug(fname) {"subscription.ingroup=#{ingroup} include? notif_obj.group=#{notif_obj.group.name} "}
          # LOG.debug(fname) {"subscription.inproject=#{inproject} include? notif_obj.projowner=#{notif_obj.projowner.ident}"} if notif_obj.respond_to? :projowner
          group_ok = ingroup.include?(notif_obj.group.name)
          # LOG.debug(fname) {"group_ok=#{group_ok}"}
          project_ok = if notif_obj.respond_to? :projowner
                         inproject.include?(notif_obj.projowner.ident)
                       else
                         true
                       end
          # LOG.debug(fname) {"project_ok=#{project_ok}"}
          if group_ok || project_ok
            if to_notify[notif].nil?
              notify[:to_notify] = true
              to_notify[notif] = notify
              LOG.debug(fname) { "notif to_notify='#{notif}'" }
            else
              LOG.debug(fname) { "notif to_notify='#{notif}'  but already include" }
            end
          end
        end
      end
    end
    to_notify
  end

  def could_show_object?
    fname = "#{self.class.name}.#{__method__}"
    ret = !(::Plmobserver::EVENTS_DESTROY.include? event_type.to_sym)
    # LOG.debug(fname){"EVENTS_DESTROY=#{::Plmobserver::EVENTS_DESTROY}:#{self.event_type}:ret=#{ret}"}
    ret
  end

  def self.send_notifications(to_notify, from, user)
    fname = "#{self.class.name}.#{__method__}"
    LOG.info(name) { "#{to_notify.count} notification to send for #{user.login}" }
    txt = nil
    if to_notify.count > 0
      notifs = {}
      recordset = []
      to_notify.each do |tonotif, _notify|
        # LOG.debug(fname) {"tonotif=#{tonotif.inspect}"}
        recordset << tonotif
      end
      notifs[:recordset] = recordset

      LOG.debug(fname) { "fromuser='#{from.login}' frommail='#{from.email}' touser='#{user.login}' tomail='#{user.email}'" }
      email = PlmMailer.notify(notifs, from, user)
      LOG.debug(fname) { "email=#{email}" }
      LOG.debug(fname) { 'fin email' }
      ###################
      # TODO syl test
      # email=nil
      ###################
      if email.nil?
        LOG.warn(fname) { "ctrl_mail_not_created pour #{user.login}" }
        msg = :mail_not_created
      else
        cnt = to_notify.count
        msg = :mail_delivered
      end
      # update notification users
      recordset.each do |notif|
        LOG.warn(fname) { "notif.notify_users=#{notif.notify_users}" }
        prefixe = "#{notif.notify_users}," unless notif.notify_users.blank?
        txt = "#{prefixe}#{user.login}:#{msg}"
        notif.update_attributes(notify_users: txt.to_s)
      end
    else
      msg = :nothing_to_notify
    end
    msg
  end
end
