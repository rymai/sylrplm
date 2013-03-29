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
  #pour get_controller_from_model_type
  include Models::SylrplmCommon
  validates_presence_of :forobject_type, :forobject_id,  :event_date, :event_type
  belongs_to :responsible,
  :class_name => "User"

  def initialize(*args)
    super
    unless args[0][:user].nil?
			self.set_default_values_with_next_seq
		end
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
     ret[:qry] = "forobject_type LIKE :v_filter or #{qry_responsible_id} or #{qrys_object_ident} or event_type LIKE :v_filter or to_char(event_date, 'YYYY/MM/DD')  LIKE :v_filter or to_char(notify_date, 'YYYY/MM/DD') LIKE :v_filter"
      ret[:values] = { v_filter: filter }
    end
    ret
  end

  def self.notify_all(id)
    name=":"+self.class.name+"."+__method__.to_s+":"
    from=User.find_by_login(::SYLRPLM::USER_ADMIN)
    ret=[]
    if id.nil? || id == "all"
      notifs=self.find(:all, :conditions => ["notify_date is null"])
    else
      notifs=Notification.find(params[:id])
    end
    the_notifs=[]
    notifs.each do |notif|
      the_notifs << {:notif => notif, :to_notify => false, :notify => true}
    end
    User.all.each do |user|
      cnt=0
      msg=nil;
      unless user.email==""
        to_notify=[]
        the_notifs.each do |notif|
          if notif[:notif].responsible == user
            notif[:to_notify] = true
            to_notify<<notif[:notif]
          end
        end
        LOG.info(name){to_notify.count.to_s+" notification for "+user.login}
        if to_notify.count > 0
          #puts to_notify.inspect
          notifs={}
          notifs[:recordset]=to_notify
          email=PlmMailer.create_notify(notifs, from, user)
          unless email.nil?
            email.set_content_type("text/html")
            PlmMailer.deliver(email)
            cnt = to_notify.count
            msg = :ctrl_mail_created_and_delivered
          else
            LOG.warn (name){"message non cree pour #{user.login}"}
            msg = :ctrl_mail_not_created
          end
        else
          msg = :ctrl_nothing_to_notify
        end
      else
        LOG.warn (name){"pas de email pour #{user.login}"}
        msg=:ctrl_user_no_email
      end
      if cnt ==0
        the_notifs.each do |notif|
          if notif[:notif].responsible == user
            notif[:notify]=false
          end
        end
      end
      ret<< { :user => user, :count => cnt, :msg => msg }
    end
    the_notifs.each do |notif|
      if notif[:notify] == true
        notif[:notif].update_attributes({:notify_date => Time.now})
      end
    end
    #puts name+"ret="+ret.inspect
    ret
  end

end
