class Volume < ActiveRecord::Base
  validates_presence_of :name, :directory
  validates_uniqueness_of :name
  has_many :documents
  has_many :users
  
  def self.create_new()
    obj=Volume.new
    Sequence.set_default_values(obj, self.name, true)
    obj
  end
  
  def self.find_all
    find(:all, :order=>"name")
  end 
  def self.find_first
    find(:first, :order=>"name")
  end 
  
  def is_used
    self.users.count >0 || self.documents.count >0
  end
  
  def create_dir(olddir)
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
  
  def destroy_volume
    lst=_list_files_
    ret=nil
    if !is_used
      ret=_destroy_volume_
    else
      ret="is_used"
    end
    ret
  end
  
  def list_files
    _list_files_
  end
  
  :private
  
  def _list_files_
    dir=File.join(self.directory,self.name)
    ret=""
    if(File.exists?(dir))
      Dir.foreach(dir) { |objectdir| 
        if(objectdir!="." && objectdir!="..")
          dirobject=File.join(dir,objectdir)
          if(File.directory?(dirobject))
            Dir.foreach(dirobject) { |iddir|     
              if(iddir!="." && iddir!="..")
                dirid=File.join(dirobject,iddir)
                ret+="\ndirid="+iddir+"="+dirid
                if(File.directory?(dirid))
                  files=Dir.entries(dirid)
                  if(files.size>2)
                    ret+=":nb="+files.size.to_s+":id="+iddir
                    for f in  files
                      ret+=":"+f
                    end
                    
                  end
                else
                  ret+="\nbad file:"+dirid               
                end
              end
            }
          else
            ret+="\nbad file:"+dirobject          
          end
        end
      } 
      ret
    end
  end
  
  def _destroy_volume_
    strm=FileUtils.remove_dir self.get_dir_name
    stdel=self.destroy
    puts "volume._destroy_volume_:strm="+strm.to_s+":stdel="+stdel.to_s
    strm.to_s+"."+stdel.to_s
    nil
  end
  
  def get_dir_name
    File.join(self.directory,self.name)
  end
  
end
