#require 'lib/controllers/plm_object_controller_module'
class Controller 
  attr_accessor :id, :name, :method
  def initialize(i_id,i_name,i_method)
    @id=i_id 
    @name=i_name
    @method=i_method
  end
  
  def name_method
    ret=@name+"."+@method
    ret
  end
  
  def self.get_controllers
    ret=[] 
    i=0
    controllers = Dir.new("#{RAILS_ROOT}/app/controllers").entries
    controllers.each do |controller|
      if controller =~ /_controller.rb/ 
        ###puts "Controller.get_controllers:"+controller
        cont = controller.camelize.gsub(".rb","")
        #- Object.methods -
        #ApplicationController.methods -
        #ApplicationController.new.methods
         (eval("#{cont}.new.methods") -
        ApplicationController.new.methods).sort.each {|smet|
          met=smet.to_s
          if(met!='index' && met!='init_objects' && met!='login' && met!='logout' && met.index('_old')==nil && met.index('_obsolete')==nil)
            ret<< Controller.new(i,cont,met)
          elsif (cont=="SessionsController")
            ret<< Controller.new(i,cont,met)
          end
          i=i+1;
        }
      end
    end
    ret   
  end
  
end
