require 'link'
require 'models/plm_object'
require 'models/sylrplm_common'
class Notification < ActiveRecord::Base
  #pour get_controller_from_model_type
  include Models::SylrplmCommon
  validates_presence_of :object_type, :object_id,  :event_date, :event_type
  belongs_to :responsible,
  :class_name => "User"
  
  def init_mdd
    create_table "notifications", :force => true do |t|
      t.string   "object_type"
      t.integer  "object_id"
      t.date     "event_date"
      t.text     "event_type"
      t.integer  "responsible_id"
      t.date     "notify_date"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.create_new(params)
    obj=Notification.new(params)
    obj.set_default_values( true)
    puts obj.inspect
    obj
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
    ret=get_object(self.object_type, self.object_id)
    puts name +" object="+ret.inspect
    ret
  end

  def to_s
    id.to_s+" "+event_type+" "+object_type+":"+object_id.to_s+" at "+event_date.to_s+" by "+responsible.login+" => "+notify_date.to_s
  end

  def self.get_conditions(filter)  
    filter = filters.gsub("*","%")
    ret={}
    unless filter.nil?
      ret[:qry] = "object_type LIKE :v_filter "+
      " or "+qry_responsible+
      " or "+qrys_object_ident+
      " or event_type LIKE :v_filter "+
      " or event_date LIKE :v_filter or notify_date LIKE :v_filter "
      ret[:values]={:v_filter => filter}
    end
    ret
    #conditions = ["object_type LIKE ? "+
    #  " or "+qry_responsible+
    #  " or "+qrys_object_ident+
    #  " or event_type LIKE ? "+
    #  " or event_date LIKE ? or notify_date LIKE ? ",
  end
  
  def self.notify_all(id)
    name=":"+self.class.name+"."+__method__.to_s+":"
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
        puts "******"+user.login+":"+to_notify.count.to_s
        if to_notify.count > 0
          puts to_notify.inspect
          notifs={}
          notifs[:recordset]=to_notify
          email=PlmMailer.create_notify(notifs, SYLRPLM::ADMIN_MAIL, user)
          unless email.nil?
            email.set_content_type("text/html")
            PlmMailer.deliver(email)
            cnt = to_notify.count
            msg = :ctrl_mail_created_and_delivered
          else
            puts name+" message non cree pour #{user.login}"
            msg = :ctrl_mail_not_created
          end
        else
          msg = :ctrl_nothing_to_notify
        end
      else
        puts name+" pas de email pour #{user.login}"
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
