require 'openwfe/representations'
require 'ruote/sylrplm/workitems'

module Models::PlmObject
  #  include OpenWFE::Extras::ArWorkitem
  #  include OpenWFE::Extras::HistoryEntry
  # modifie les attributs avant edition
  def self.included(base)
    base.extend(ClassMethods) # �a appelle extend du sous module ClassMethods sur "base", la classe dans laquelle tu as inclue la lib
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

  # renvoie le type de l'objet: nom de la classe en minuscule
  def object_type
    self.class.name.downcase
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
    check=Check.get_checkout(self.class.name, self)
    #file=self.filename
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
        obj=clone()
        obj.revision=rev_cur.next
        obj.statusobject=Statusobject.get_first(self.class.name)
        puts self.class.name+".revise:"+rev_cur+"->"+obj.revision
        if self.has_attribute?(:filename)
          if(self.filename!=nil)
            content=self.read_file
            obj.write_file(content)
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

  def get_workitems
    ret=[]
    links=Link.find_fathers(self.object_type, self,  "workitem")
    links.each do |link|
      begin
        #father=OpenWFE::Extras::ArWorkitem.find(link.father_id)
        father=Ruote::SylArWorkitem.find(link.father_id)
        #puts "plm_object.get_workitems:workitem="+father.inspect
        father.link_attributes={"relation"=>link.name}
        ret<<father
      rescue Exception =>e
        LOG.error "plm_object.get_workitems:erreur="+e.inspect
      end
    end
    #puts "plm_object.get_workitems:ret="+ret.size.to_s
    ret
  end

  def get_histories
    ret=[]
    links=Link.find_fathers(self.object_type, self,  "history")
    links.each do |link|
      begin
        father = Ruote::SylHistoryEntry.find(link.father_id)
        #puts "plm_object.get_histories:history="+father.inspect
        father.link_attributes={"relation"=>link.name}
        ret<<father
      rescue Exception => e
        LOG.error "plm_object.get_histories:erreur="+e.inspect
      end
    end
    #puts "plm_object.get_histories:ret="+ret.size.to_s
    ret
  end

end