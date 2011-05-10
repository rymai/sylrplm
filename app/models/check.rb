class Check < ActiveRecord::Base
  include Models::SylrplmCommon
  #validates_presence_of :out_reason
  #validates_uniqueness_of [:object,:object_id,:status]

  belongs_to :documents , :conditions => ["object='document'"]

  #status:
  # 0=unknown
  # 1=out
  # 2=in
  # 3=free
  def self.get_checkout(object_cls, object)
    find(:last, :conditions => ["object = '#{object_cls}' and object_id=#{object.id} and status=1"])
  end

  def self.create_new(object_cls, object, params, user)
    if(params)
      # commit genere par le view 
      params.delete("commit")
      params.delete("authenticity_token")
      params.delete("_method")
      params.delete("action")
      params.delete("controller")
      obj=Check.new(params)
    else
      obj=Check.new
    end
    obj.object=object_cls
    obj.object_id=object.id
    obj.status=1
    obj.out_user=user
    obj.out_date=DateTime.now
    obj.set_default_values(true)
    obj
  end

  def checkIn(params, user)
    self.status=2
    self.in_user=user
    if(params)
      # commit genere par le view 
      params.delete("commit")
      params.delete("authenticity_token")
      params.delete("_method")
      params.delete("action")
      params.delete("controller")
      self.in_reason=params[:reason]
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
      self.in_reason=params[:reason]
    end
    self.in_date=DateTime.now
  end

  def self.get_conditions(filter)
    nil
  end

end
