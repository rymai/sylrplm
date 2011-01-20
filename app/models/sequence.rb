class Sequence < ActiveRecord::Base
  include Models::SylrplmCommon
  validates_presence_of :utility, :value 
  validates_uniqueness_of :utility    
  
  def self.get_next_seq(utility)
    current=find_for(utility) 
    ret=nil
    if(current != nil)
      old=current.value
      ret=current.value.next 
      current.update_attribute("value",ret)
    end
    ret
  end
  
  def self.get_constants
    Module.constants.select do |constant_name|
      constant = eval constant_name
      isClass=constant.is_a? Class
      puts 'ApplicationController.get_constants='+constant.to_s+' class='+isClass.to_s
      #if not constant.nil? && isClass && constant.extend? ActiveRecord::Base
      
    end
  end 
  
  def self.find_all
    find(:all, :order=>"utility")
  end
  
  def self.find_for(utility)
    find(:first, :order=>"utility", :conditions => ["utility = '#{utility}' "])
  end
  
  # recherche des attributs d'un modele
  def self.find_cols_for(model)
    ret=[]
    find_all.each do |line|
      tokens=line.split(".")[0]
      if(tokens[0]==model)
        ret<<tokens[1]
        end
    end
    ret
  end
  
  # recherche d'un attribut d'un modele
  def self.find_col_for(model,col)
    ret=nil
    find_all.each do |line|
        tokens=line.utility.split(".")
        ##puts "Sequence.find_col_for:"+model+"."+col+":"+line.utility
        if(tokens[0]==model && tokens[1]==col)
          ret=line
        end
    end
    ret
  end
  
   def self.get_conditions(filter)
    nil
  end
    
end
