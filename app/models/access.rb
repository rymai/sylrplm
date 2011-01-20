#require 'lib/models/sylrplm_common'
class Access < ActiveRecord::Base
  include Models::SylrplmCommon
  
  validates_presence_of :controller, :roles , :action
  #validates_uniqueness_of :controller ,:role_id,:action
  
  def self.create_new(i_controller, i_roles)
    obj=Access.new
    conts=i_controller.split(".")
    obj.controller=conts[0]
    obj.action=conts[1]
    obj.roles=i_roles
    obj.set_default_values(true)
    obj
  end
  
  def self.find_for_controller(i_controller)
    ret={}
    #puts 'access.find_for_controller='+i_controller
    self.find(:all, :order=>"controller",
          :conditions => ["controller like '#{i_controller}'"]).each do |acc|
      ret[acc.action.to_sym]=acc.roles
    end
    ret
  end
  
  def self.init
    ret=true
    Controller.get_controllers.each do |controller|
      st=0
      if controller.name !="AccessesController" &&
        controller.name !="LoginController" &&
        controller.name !="PlmInitController" &&
        controller.name !="RolesController" &&
        controller.name !="RolesUsersController" &&
        controller.name !="SequencesController" &&
        controller.name !="SessionsController"
        st=st+create_access(controller.name,controller.method,"admin & !designer & !consultant") 
      else
        if controller.name =="SessionsController"
          st=st+create_access(controller.name,controller.method,"admin | designer | consultant") 
        else
          st=st+create_access(controller.name,controller.method,"(admin | designer) & !consultant") 
        end
      end
      #puts 'access_controller.index:controller='+controller.name+' method='+controller.method+' st='+st.to_s     
    end
    true
  end
  
  def self.create_access(ctrl,met,roles)
    access=new
    access.controller=ctrl
    access.action=met
    access.roles=roles
    puts "access.create_access:"+access.inspect
    if !access.save
      return 1 
    else
      return 0
    end
  end
  
  def self.get_conditions(filter)
    filter=filter.gsub("*","%")
    ["controller LIKE ? or action LIKE ? or roles LIKE ? " ,
    filter, filter, 
    filter] unless filter.nil? 
  end
  
end
