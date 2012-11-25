require_dependency 'lib/models/sylrplm_common'

class Check < ActiveRecord::Base
  include Models::SylrplmCommon
  #validates_presence_of :out_reason
  #validates_uniqueness_of [:object,:object_id,:status]

  belongs_to :documents , :conditions => ["object='document'"]
  belongs_to :out_user,
    :class_name => "User"
  belongs_to :in_user,
    :class_name => "User"
  belongs_to :out_group,
    :class_name => "Group"
  belongs_to :in_group,
    :class_name => "Group"
  belongs_to :projowner,
    :class_name => "Project"
  attr_accessor :user

  #status:
  # 0=unknown
  # 1=out
  # 2=in
  # 3=free
  def self.get_checkout(object)
    find(:last, :conditions => ["object = '#{object.class.name}' and object_id=#{object.id} and status=1"])

  def initialize(*args)
    super
    self.status    = 1
    self.out_date  = Time.now.utc
    self.set_default_values(true) if args.empty?
  end

  def user=(user)
    self.out_user  = user
    self.out_group = user.group
    self.projowner = user.project
  end

  def self.create_new(object_cls, object, params, user)
    if(params)
      params.delete("action")
    else
    end
    obj.object_id=object.id
    obj.status=1
    raise Exception.new "Don't use this method!"
  end

  def checkIn(params, user)
    self.status = 2
    self.in_user = user
    self.in_group = user.group
    self.projowner = user.project
    if(params)
      # commit genere par le view
      params.delete("commit")
      params.delete("authenticity_token")
      params.delete("_method")
      params.delete("action")
      params.delete("controller")
      self.in_reason = params[:in_reason]
    end
    self.in_date=DateTime.now
  end

  def checkFree(params, user)
    self.status=3
    self.in_user=user
    if(params)
      # commit genere par le view
      params.delete("commit")
      params.delete("authenticity_token")
      params.delete("_method")
      params.delete("action")
      params.delete("controller")
      self.in_reason = params[:in_reason]
    end
    self.in_date=DateTime.now
  end

  def self.get_conditions(filter)
    nil
  end

end
