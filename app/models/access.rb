class Access < ActiveRecord::Base
  
  ##belongs_to :role
  
  validates_presence_of :controller, :roles , :action
  #validates_uniqueness_of :controller ,:role_id,:action
  
  def self.create_new(i_controller, i_roles)
    obj=Access.new
    conts=i_controller.split(".")
    obj.controller=conts[0]
    obj.action=conts[1]
    obj.roles=i_roles
    Sequence.set_default_values(obj, self.name, true)
    obj
  end
  
  def self.find_for_controller(i_controller)
    ret={}
    puts 'access.find_for_controller='+i_controller
    self.find(:all, :order=>"controller",
          :conditions => ["controller like '#{i_controller}'"]).each do |acc|
      #conts=acc.controller.split(".")
      
      #        puts 'access.find_for_controller:controller='+acc.controller
      #        puts 'access.find_for_controller:method='+acc.action
      #        puts 'access.find_for_controller:roles='+acc.roles
      ret[acc.action.to_sym]=acc.roles
      
    end
    
    ret
  end
  
  def self.init
    ret=true
    #admin_role=Role.find_by_name('admin')
    #conc_role=Role.find_by_name('designer')
    #cons_role=Role.find_by_name('consultant')
    #puts "access.init:roles="+admin_role.inspect
    #puts "access.init:"+conc_role.inspect
    #puts "access.init:"+cons_role.inspect
    Controller.get_controllers.each do |controller|
      st=0
      if controller.name !="AccessesController" &&
        controller.name !="LoginController" &&
        controller.name !="PlmInitController" &&
        controller.name !="RolesController" &&
        controller.name !="RolesUsersController" &&
        controller.name !="SequencesController"
        st=st+create_access(controller.name,controller.method,"admin & !designer & !consultant") 
      else
        st=st+create_access(controller.name,controller.method,"(admin | designer) & !consultant") 
      end
      puts 'access_controller.index:controller='+controller.name+' method='+controller.method+' st='+st.to_s
      
      
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
  
  
end
