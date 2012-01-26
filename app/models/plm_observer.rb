require 'models/plm_object'
require 'models/sylrplm_common'

class PlmObserver < ActiveRecord::Observer
  include Models::PlmObject
  include Models::SylrplmCommon
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
    name="****************"+self.class.name+"."+__method__.to_s+":"
    #puts name+object.inspect
    add_notification(__method__.to_s, object)
  end

  def before_create(object)
    name="****************"+self.class.name+"."+__method__.to_s+":"
    #puts name+object.inspect

  end

  def after_create(object)
    name="****************"+self.class.name+"."+__method__.to_s+":"
    #puts name+object.inspect
    #add_notification(__method__.to_s, object)
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
    #add_notification(__method__.to_s, object)
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
    name="****************"+self.class.name+"."+__method__.to_s+":"
    #puts name+event_type+":"+object.inspect
    unless object.model_name==self.model_name
      params={}
      params[:object_type] = object.model_name
      params[:object_id] = object.id
      params[:event_date] = object.updated_at
      params[:event_type] = event_type
      params[:responsible] = object.owner
      notif=Notification.create_new(params)
      #puts name+notif.inspect
      unless notif.nil?
        notif.save
      end
    end
    notif
  end

end