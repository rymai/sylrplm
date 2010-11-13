module PlmObject 
  
  # modifie les attributs avant edition
  def edit()
    self.date=DateTime::now()
  end
  
  def isFreeze
    if(self.statusobject!=nil && Statusobject.find_last(self.class.name)!=nil)
      if(self.statusobject.rank == Statusobject.find_last(self.class.name).rank)
        true
      else
        false
      end
    else
      false
    end
  end
  
  # a valider si avant dernier status
  def isToValidate
    if(self.statusobject!=nil && Statusobject.find_last(self.class.name)!=nil)
      if(self.statusobject.rank == Statusobject.find_last(self.class.name).rank-1)
        true
      else
        false
      end
    else
      false
    end 
  end
  
  def is_checked
    check=Check.findCheckout(self.class.name, self) 
    file=self.filename
    if(check.nil?)
      #non reserve
      false
    else
      #reserve
      true
    end
  end
  
  def uploaded_file=(file_field)
    self.removeFile
    fname=base_part_of(file_field.original_filename)
    self.filename=fname
    self.content_type=file_field.content_type.chomp
    content=file_field.read
    writeFile(content)
  end
  
  def base_part_of(file_name)
    File.basename(file_name).gsub(/[^\w._-]/, '')    
  end
  
  def revise 
    if(self.isFreeze)
      # recherche si c'est la derniere revision
      rev_cur=self.revision
      last_rev=find_last_revision(self)
      puts "plm_object.revise:"+rev_cur.to_s+"->"+last_rev.revision.to_s
      if(last_rev.revision==rev_cur)
        obj=clone()      
        obj.revision=rev_cur.next
        obj.statusobject=Statusobject.find_first(self.class.name)
        puts self.class.name+".revise:"+rev_cur+"->"+obj.revision
        if self.has_attribute?(:filename)
          if(self.filename!=nil)
            content=self.readFile
            obj.writeFile(content)
          end
        end
        return obj
      else
        return nil
      end
    else
      return nil
    end    
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
  
  def getRepository
    repos=self.volume.directory+"/"+self.volume.name+"/"+self.class.name
    if !File.exists?(repos)
      begin 
        Dir.mkdir(repos)
      rescue Errno::ENOENT
        puts "plm_object.getRepository:pb mkdir:"+repos
        return nil
      end
    end  
    repos+="/"+self.ident
    if !File.exists?(repos)
      begin 
        Dir.mkdir(repos)
      rescue Errno::ENOENT
        puts "plm_object.getRepository:pb mkdir:"+repos
        return nil
      end
    end  
    if(self.filename!=nil)
      rev=self.revision
      if rev==nil 
        # if @params[:revision]!=nil
        #   rev=@params[:revision]
        # end
      end 
      puts "plm_object.getRepository:revision="+rev.to_s+" filename="+self.filename.to_s
      repos+="/"+rev+"_"+self.filename
    end
    return repos
  end
  
  def readFile
    data = ''
    f = File.open(getRepository, "r") 
    f.each_line do |line|
      data += line
    end
    return data
  end
  
  def writeFile(content)
    f = File.open(getRepository, "w") 
    puts "writeFile:"+getRepository
    f.puts(content)
    f.close          
  end  
  
  # inutilisee, voir application_controller.getModelsAndColumns
  def self.getColumns
    ret=[]
    self.content_columns().each do |col|
      if(col.name != 'created_at' && col.name != 'updated_at' && col.name != 'owner')
        ret<<col.name
      end
    end
    return ret
  end
  
end
