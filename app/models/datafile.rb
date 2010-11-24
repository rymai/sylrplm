require 'lib/models/plm_object'
class Datafile < ActiveRecord::Base
  include PlmObject
  
  validates_presence_of :ident , :typesobject
  validates_uniqueness_of :ident, :scope => :revision
  
  belongs_to :typesobject
  belongs_to :volume
  belongs_to :owner,
    :class_name => "User",
    :foreign_key => "owner_id" 
  
  def self.createNew(params,user)
    #puts "datafile.createNew:user="+user.inspect
    if(params==nil)   
      datafile=new 
      Sequence.set_default_values(datafile, self.name,true)
      datafile.volume=user.volume
      datafile.owner=user
      datafile.revision="1"
      ret=true
    else
      parameters=params[:datafile]
      uploaded_file=parameters[:uploaded_file]
      #contournement pour faire le upload apres la creation pour avoir la revision dans
      #getRepository !!!!!!!!!!!!!!
      parameters.delete(:uploaded_file)
      parameters[:volume]=user.volume
      parameters[:owner]=user
      puts "datafile.createNew:param="+parameters.inspect
      datafile=new(parameters)
      #puts "datafile.createNew:save1="+datafile.errors.inspect
      if datafile.save   
        # on sauve le fichier maintenant et le tour est joue
        self.createDir
        datafile.update_attributes(:uploaded_file=>uploaded_file)
        datafile.save
      end
    end
    puts __FILE__+":"+datafile.inspect
    datafile
  end
  
  def update_attributes_repos(parameters, user)
    uploaded_file=parameters[:uploaded_file]
    puts "datafile.parameters:param="+parameters.inspect
    parameters[:volume]=user.volume
    if(uploaded_file)
      parameters.delete(:uploaded_file)
      parameters[:revision]=self.revision.next
      self.update_attributes(parameters)
      createDir
      self.update_attributes(:uploaded_file=>uploaded_file)
    else
      self.update_attributes(parameters)
    end
    #if isUploaded
    
    #end
    
    ##mv_to_volume
  end
  
  def uploaded_file=(file_field)
    puts "plm_object.uploaded_file=:file_field="+file_field.inspect
    puts "plm_object.uploaded_file=:self="+self.inspect
    if (file_field!=nil && file_field!="" && file_field.original_filename!=nil && file_field.original_filename!="")
      ##self.removeFile
      ##self.filename=fname+"##"+file_field.path
      content=file_field.read
      self.content_type=file_field.content_type.chomp
      self.filename=base_part_of(file_field.original_filename)
      writeFile(content)
    end
  end
  
  #  def isUploaded
  #    ret=false
  #    if self.filename 
  #      ret=self.filename.index("##")!=nil
  #    end
  #  end
  
#  def mv_to_volume
#    fields=self.filename.split("##")
#    puts "plm_object.mv_to_volume:fields="+fields.inspect
#    tmpfile=File.new(fields[1],"r")
#    content=tmpfile.read
#    self.filename=fields[0]
#    self.save
#    createDir
#    writeFile(content)
#  end
  
  def base_part_of(file_name)
    File.basename(file_name).gsub(/[^\w._-]/, '')    
  end
  
  def getDirRepository
    File.join self.volume.getDirName, self.class.name, self.ident
  end
  
  def getRepository
    # on prend le volume du fichier lui meme
    puts "plm_object.getRepository:file="+self.inspect
    repos=getDirRepository
    #        begin 
    #          FileUtils.mkdir_p(repos)
    #        rescue Errno::ENOENT
    #          puts "plm_object.getRepository:pb mkdir:"+repos
    #          return nil
    #        end
    if(self.filename!=nil)
      rev=self.revision
      if rev==nil 
        # if @params[:revision]!=nil
        #   rev=@params[:revision]
        # end
        repos=File.join(repos, rev.to_s+"_"+self.filename)
      else
        repos=File.join(repos, self.filename)
      end 
      puts "plm_object.getRepository:revision="+rev.to_s+" filename="+self.filename.to_s
    end
    repos
  end
  
  def readFile
    data = ''
    f = File.open(getRepository, "r") 
    f.each_line do |line|
      data += line
    end
    return data
  end
  
  def createDir
    FileUtils.mkdir_p(getDirRepository)
  end
  
  def writeFile(content)
    f = File.open(getRepository, "w") 
    puts "writeFile:"+getRepository
    f.puts(content)
    f.close          
  end  
  
  def removeFile
    repos=getRepository
    if(repos!=nil)
      if (File.exists?(repos))
        begin
          File.unlink(repos)
        rescue 
          return self
        end
      end
    else
      return nil
    end
    self
  end
end
