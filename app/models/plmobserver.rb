# frozen_string_literal: true

require 'models/plm_object'
require 'models/sylrplm_common'

class Plmobserver < ActiveRecord::Observer
  # include Models::PlmObject
  include Models::SylrplmCommon

  observe :customer, :document, :part, :project
  # list of modelname observed by this observer,
  # TODO: instead of this constant, use introspection by using observe method just above
  MODELS_OBSERVE = %w[customer document part project].freeze

  EVENTS_DESTROY = [:before_destroy, :after_destroy].freeze

  def initialize(*args)
    super
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"args=#{args.inspect}"}
  end

  def before_validation(_object)
    fname = '****************' + "#{self.class.name}.#{__method__}" + ':'
    # puts name+object.inspect
  end

  def after_validation(_object)
    fname = '****************' + "#{self.class.name}.#{__method__}" + ':'
    # puts name+object.inspect
  end

  def before_save(_object)
    fname = '****************' + "#{self.class.name}.#{__method__}" + ':'
    # puts name+object.inspect
  end

  def after_save(object)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "object=#{object} " }
    add_notification(__method__.to_s, object)
  end

  def before_create(_object)
    name = '****************' + "#{self.class.name}.#{__method__}" + ':'
    # puts name+object.inspect
  end

  def after_create(object)
    name = '****************' + "#{self.class.name}.#{__method__}" + ':'
    # puts name+object.inspect
    add_notification(__method__.to_s, object)
  end

  def around_create(_object)
    name = '****************' + "#{self.class.name}.#{__method__}" + ':'
    # puts name+object.inspect
    # add_notification(__method__.to_s, object)
  end

  def before_update(_object)
    fname = '****************' + "#{self.class.name}.#{__method__}" + ':'
    # LOG.debug(fname){"object=#{object.inspect}"}
  end

  def after_update(object)
    fname = '****************' + "#{self.class.name}.#{__method__}" + ':'
    LOG.debug(fname) { "object=#{object.inspect}" }
    add_notification(__method__.to_s, object)
  end

  def around_update(object)
    fname = '****************' + "#{self.class.name}.#{__method__}" + ':'
    LOG.debug(fname) { "object=#{object.inspect}" }
    # add_notification(__method__.to_s, object)
  end

  def before_destroy(_object)
    fname = '****************' + "#{self.class.name}.#{__method__}" + ':'
    # add_notification(__method__.to_s, object)
  end

  def after_destroy(object)
    name = '****************' + "#{self.class.name}.#{__method__}" + ':'
    LOG.debug(fname) { "object=#{object.inspect}" }
    add_notification(__method__.to_s, object)
  end

  def around_destroy(object)
    fname = '****************' + "#{self.class.name}.#{__method__}" + ':'
    LOG.debug(fname) { "object=#{object.inspect}" }
    # add_notification(__method__.to_s, object)
  end

  def add_notification(event_type, object)
    fname = '****************' + "#{self.class.name}.#{__method__}" + ':'
    LOG.debug(fname) { "event_type=#{event_type} , object=#{object.inspect}" }
    unless object.modelname == modelname
      params = {}
      params[:forobject_type] = object.modelname
      params[:forobject_id] = object.id
      params[:event_date] = object.updated_at
      params[:event_type] = event_type
      params[:responsible] = object.owner
      Notification.create(params)
    end
  end
end
