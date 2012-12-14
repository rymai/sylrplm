require_dependency 'lib/models/sylrplm_common'

class Check < ActiveRecord::Base
  include Models::SylrplmCommon

  attr_accessor :user

  belongs_to :out_user, :class_name => "User"
  belongs_to :in_user, :class_name => "User"
  belongs_to :out_group, :class_name => "Group"
  belongs_to :in_group, :class_name => "Group"
  belongs_to :projowner, :class_name => "Project"
  ##belongs_to :checkobject, :polymorphic => true

  #status:
  # 0=unknown
  # 1=out
  # 2=in
  # 3=free
  def self.get_checkout(object)
    find(:last, :conditions => ["checkobject = ? and checkobject_id = ? and status = 1", object.model_name, object.id])
  end

  def initialize(*args)
     fname= "#{self.class.name}.#{__method__}"
    LOG.info (fname) {"args=#{args}"} 
    super
   
    self.status    = 1
    self.out_date  = Time.now.utc
    self.set_default_values(true) if args.length==1
  end

  def user=(user)
    fname= "#{self.class.name}.#{__method__}"
    LOG.info (fname) {"user=#{user}"} 
    self.out_user  = user
    self.out_group = user.group
    self.projowner = user.project
  end
  
  def object_to_check=(obj)
    fname= "#{self.class.name}.#{__method__}"
    LOG.info (fname) {"obj=#{obj}"} 
    self.checkobject  = obj.model_name
    self.checkobject_id = obj.id
  end

  def self.create_new(object_cls, object, params, user)
    raise Exception.new "Don't use this method!"
  end

  def checkIn(params, user)
    self.attributes = params
    self.status = 2
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
    self.status = 3
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
