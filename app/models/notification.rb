class Notification < ActiveRecord::Base
  include Models::SylrplmCommon
  #pour get_controller_from_model_type
  
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
  def self.notify
    name="****************begin:"+self.class.name+"."+__method__.to_s+":"
    User.all.each do |user|
      to_notify=[]
      notifs=self.find(:all, :conditions => ["notify_date != ''"])
      notifs.each do |notif|
        if notif.responsible == user
          to_notify << notif
        end
      end
      puts "**********"+user.login+":"+to_notify.count.to_s
      if to_notify.count > 0
        puts to_notify.inspect
        notifs={}
        notifs[:recordset]=to_notify
        email=PlmMailer.create_notify(notifs, SYLRPLM::ADMIN_MAIL, user)
        if(email!=nil)
          email.set_content_type("text/html")
          PlmMailer.deliver(email)
        end
      end
    end
    name="****************end:"+self.class.name+"."+__method__.to_s+":"
  end

  def to_s
    id.to_s+" "+event_type+" "+object_type+":"+object_id.to_s+" at "+event_date.to_s+" by "+responsible.login+" => "+notify_date.to_s
  end

  def self.get_conditions(filter)
    filter=filter.gsub("*","%")
    conditions = ["object_type LIKE ? "+
      " or "+qry_responsible+
      " or "+qrys_object_ident+
      " or event_type LIKE ? "+
      " or event_date LIKE ? or notify_date LIKE ? ",
      filter, filter,
      filter, filter,
      filter, filter] unless filter.nil?
  end
end
