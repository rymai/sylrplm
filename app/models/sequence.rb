class Sequence < ActiveRecord::Base
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
      #if not constant.nil? and isClass and constant.extend? ActiveRecord::Base
      
    end
  end 
  
  # attribution de valeurs par defaut suivant la table sequence
  def self.set_default_values(object, model, next_seq)
    #find_cols_for(model).each do |strcol|
    # object.column_for_attribute(strcol)=
    #get_constants
    object.attribute_names().each do |strcol|
      old_value=object[strcol]
      col=find_col_for(model,strcol)
      val=old_value
      if(col!=nil) 
        if(col.sequence==true)
          if(next_seq==true)
            val=get_next_seq(col.utility)
          end
        else
          val=col.value
        end
        puts "sequence.set_default_values:"+strcol+"="+old_value.to_s+" to "+val.to_s
        #object.update_attribute(strcol,val)
        object[strcol]=val
      end
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
        puts "find_col_for:"+model+"."+col+":"+line.utility
        if(tokens[0]==model && tokens[1]==col)
          ret=line
        end
    end
    ret
  end
  
    
end
