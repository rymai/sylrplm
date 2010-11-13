require 'fileutils'
class Volume < ActiveRecord::Base
  validates_presence_of :name, :directory
  validates_uniqueness_of :name
  has_many :documents
  
  
  def self.createNew()
    obj=Volume.new
    Sequence.set_default_values(obj, self.name, true)
    obj
  end
  
  def self.find_all
          find(:all, :order=>"name")
  end 
  
  def createDir(olddir)
    if (!File.exists?(self.directory))
      begin 
        Dir.mkdir(self.directory)
      rescue 
        return nil
      end
    end
    if(olddir!=nil)
      dirfrom=File.join(olddir,self.name)
      if(File.exists?(dirfrom))
        dirto=self.directory
        catto=File.join(olddir,dirto)
        if(catto!=dirto)
        begin
          FileUtils.mv(dirfrom, dirto)
          dir=File.join(self.directory,self.name)
          dir
        rescue 
            return nil
        end
        end
      else
        return nil
      end
    else
      #1ere creation
      dir=File.join(self.directory,self.name)
      if !File.exists?(dir)
        begin 
          Dir.mkdir(dir)
          return dir
        rescue 
          return nil
        end
      end
    end
  end
  
  
  def destroyVolume
    dir=File.join(self.directory,self.name)
    ret=""
    if(File.exists?(dir))
      Dir.foreach(dir) { |objectdir| 
        if(objectdir!="." and objectdir!="..")
          dirobject=File.join(dir,objectdir)
          #ret+="<br/>objectdir="+objectdir+"="+dirobject
          if(File.directory?(dirobject))
            Dir.foreach(dirobject) { |iddir|     
              if(iddir!="." and iddir!="..")
                dirid=File.join(dirobject,iddir)
                ret+="\ndirid="+iddir+"="+dirid
                if(File.directory?(dirid))
                  files=Dir.entries(dirid)
                  if(files.size>2)
                    ret+=":nb="+files.size.to_s+":id="+iddir
                    for f in  files
                      ret+=":"+f
                    end
                    return ret
                  end
                else
                  ret+="\nbad file:"+dirid
                  return ret
                end
               end
             }
          else
              ret+="\nbad file:"+dirobject
              return ret   
          end
        end
      } 
     
      # detruire le repertoires volume/ids
      Dir.foreach(dir) {
            |objectdir| 
        if(objectdir!="." and objectdir!="..")
          dirobject=File.join(dir,objectdir)
          Dir.foreach(dirobject) {
              |iddir|     
            if(iddir!="." and iddir!="..")
              dirid=File.join(dirobject,iddir)
              if(File.exists?(dirid))
                if(File.directory?(dirid))
                    Dir.rmdir(dirid)
                end
              end
            end
          }
          if(File.exists?(dirobject))
            Dir.rmdir(dirobject)
          end
        end
      }  
      Dir.rmdir(dir)
    end
    self.destroy
    nil    
  end
      
end
