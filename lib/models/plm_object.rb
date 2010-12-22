module Models::PlmObject 
  
  # modifie les attributs avant edition
  def self.included(base)
    base.extend(ClassMethods) # ça appelle extend du sous module ClassMethods sur "base", la classe dans laquelle tu as inclue la lib
  end
  
  module ClassMethods
    # inutilisee, voir application_controller.get_models_and_columns
    def self.get_columns
      ret=[]
      self.content_columns().each do |col|
        if(col.name != 'created_at' && col.name != 'updated_at' && col.name != 'owner')
          ret<<col.name
        end
      end
      ret
    end
  end
    
    def edit()
      self.date=DateTime::now()
    end
    
    def is_freeze
      if(self.statusobject!=nil && Statusobject.get_last(self.class.name)!=nil)
        if(self.statusobject.rank == Statusobject.get_last(self.class.name).rank)
          true
        else
          false
        end
      else
        false
      end
    end
    
    # a valider si avant dernier status
    def is_to_validate
      if(self.statusobject!=nil && Statusobject.get_last(self.class.name)!=nil)
        if(self.statusobject.rank == Statusobject.get_last(self.class.name).rank-1)
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
    
    def revise 
      if(self.is_freeze)
        # recherche si c'est la derniere revision
        rev_cur=self.revision
        last_rev=find_last_revision(self)
        puts "plm_object.revise:"+rev_cur.to_s+"->"+last_rev.revision.to_s
        if(last_rev.revision==rev_cur)
          # clonage du document
          obj=self.clone      
          obj.revision=rev_cur.next
          obj.statusobject=Statusobject.get_first(self.class.name)
          puts self.class.name+".revise:doc="+rev_cur+"->"+obj.revision
            #copie des fichiers 
            self.datafile.each { |datafile|
            puts self.class.name+".revise:datafile="+datafile.inspect
            unless datafile.filename.nil?
              content=datafile.read_file
              datafile_clone=datafile.clone
              datafile_clone.set_default_values(true)
              datafile_clone.write_file(content)
              st=datafile_clone.save
              puts self.class.name+".revise:st="+st.to_s+" clone="+datafile_clone.inspect
              unless st.nil?
                obj.datafile<<datafile_clone
              end
            end
            }
          obj
        else
          nil
        end
      else
        return nil
      end    
    end
    
      # attribution de valeurs par defaut suivant la table sequence
  def set_default_values(next_seq)
    #find_cols_for(model).each do |strcol|
    # object.column_for_attribute(strcol)=
    #get_constants
    self.attribute_names().each do |strcol|
      old_value=self[strcol]
      #col=self.find_col_for(strcol)
      col=::Sequence.find_col_for(self.class.name,strcol)
      val=old_value
      if(col!=nil) 
        if(col.sequence==true)
          if(next_seq==true)
            val=::Sequence.get_next_seq(col.utility)
          end
        else
          val=col.value
        end
        puts "sequence.set_default_values:"+strcol+"="+old_value.to_s+" to "+val.to_s
        #object.update_attribute(strcol,val)
        self[strcol]=val
      end
    end
  end
  
  
end
