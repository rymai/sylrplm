#require 'openwfe/representations'
#require 'ruote/sylrplm/workitems'

module Models::PlmObject
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

  def checked?
    check = Check.get_checkout(self.class.name, self)
    #file=self.filename
    if check.nil?
      #non reserve
      false
    else
      #reserve
      true
    end
  end
  
  def last_revision?
    ret = (self.revision == self.last_revision.revision)
    ret
  end
  
  def revisable?
    ret = (frozen? && last_revision?)
    ret
  end
  
  def revise
    if(self.is_freeze)
      # recherche si c'est la derniere revision
      rev_cur=self.revision
      last_rev=last_revision
      if(revisable?)
        obj=clone()
        obj.revision=rev_cur.next
        obj.statusobject=Statusobject.get_first(self.class.name)
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
  
  # a valider si avant dernier status
  def could_validate?
    mdl=model_name
    !(self.statusobject.nil? || Statusobject.get_last(mdl).nil?) &&
    self.statusobject.rank == Statusobject.get_last(mdl).rank-1
  end
  
  def plm_validate
    if could_validate?
      promote
    end
  end
  
  def link_relation
    if link_attributes["relation"] == "" 
      ""
    else
      link_attributes["relation"].name
    end 
  end
  
  def get_workitems
    ret = []
    links = Link.find_fathers(self.model_name, self,  "ar_workitem")
    #puts "plm_object.get_workitems:links="+links.inspect
    links.each do |link|
      begin
        father = Ruote::Sylrplm::ArWorkitem.find(link.father_id) unless Ruote::Sylrplm::ArWorkitem.count(link.father_id)==1
        #puts "plm_object.get_workitems:workitem="+father.inspect
        father.link_attributes={"relation"=>link.relation}
        ret << father
      rescue Exception => e
        #puts "plm_object.get_workitems:erreur="+e.inspect
        LOG.info "plm_object.get_workitems:erreur="+e.inspect
      end
    end
    #puts "plm_object.get_workitems:ret="+ret.inspect
    ret
  end

  def get_histories
    ret = []
    links = Link.find_fathers(self.model_name, self,  "history_entry")
    links.each do |link|
      begin
        father = Ruote::Sylrplm::HistoryEntry.find(link.father_id) unless Ruote::Sylrplm::HistoryEntry.count(link.father_id)==1
        #puts "plm_object.get_histories:history="+father.inspect
        father.link_attributes={"relation"=>link.relation}
        ret << father
      rescue Exception => e
        puts "plm_object.get_histories:erreur="+e.inspect
        LOG.error "plm_object.get_histories:erreur="+e.inspect
      end
    end
    #puts "plm_object.get_histories:ret="+ret.inspect
    ret
  end
  
  def add_documents_from_favori(favori)
    favori.items.each do |item|
      documents << item
    end
  end

  def remove_documents()
    documents = nil
  end

  def remove_document(document)
    documents.delete( document)
  end
  
  def add_parts_from_favori(favori)
    favori.items.each do |item|
      parts << item
    end
  end

  def remove_parts()
    parts = nil
  end

  def remove_part(part)
    parts.delete( part)
  end

  def add_projects_from_favori(favori)
    favori.items.each do |item|
      projects << item
    end
  end

  def remove_projects()
    projects = nil
  end

  def remove_project(item)
    projects.delete( item)
  end
  
  def add_users_from_favori(favori)
    favori.items.each do |item|
      users << item
    end
  end

  def remove_users()
    users = nil
  end

  def remove_user(item)
    users.delete( item)
  end
  
  def self.find_all
    find(:all, :order=>"ident")
  end

  def self.find_others(object_id)
    find(:all,
    :conditions => ["id != #{object_id}"],
    :order=>"ident")
  end
 
  # si meme groupe ou confidentialite = public ou confidentiel
  def ok_for_index?(user)
    acc_public = ::Typesobject.find_by_object_and_name("project_typeaccess", "public")
    acc_confidential = ::Typesobject.find_by_object_and_name("project_typeaccess", "confidential")
    #puts "ok_for_index?:acc_public="+acc_public.inspect
    #puts "ok_for_index?:acc_confidential="+acc_confidential.inspect
    #puts "ok_for_index?:self="+self.inspect
    #puts "ok_for_index?:user="+user.inspect
    #index possible meme sans user connecte 
    puts "ok_for_index? acc_public:"+self.projowner.typeaccess.name+"=="+acc_public.name
    puts "ok_for_index? acc_confidential:"+self.projowner.typeaccess.name+"=="+acc_confidential.name
    unless user.nil?
      puts "ok_for_index? group:"+self.group.name+"=="+user.group.name
      (self.group_id==user.group.id || self.projowner.typeaccess_id==acc_public.id || self.projowner.typeaccess_id==acc_confidential.id)
    else
      (self.projowner.typeaccess_id==acc_public.id || self.projowner.typeaccess_id==acc_confidential.id)
    end
    true
  end
  
  # si meme groupe ou confidentialite = public 
  def ok_for_show?(user)
    acc_public = Typesobject.find_by_object_and_name("project_typeaccess", "public")
    #index possible meme sans user connecte
    #puts "ok_for_show? acc_public:"+self.projowner.typeaccess.name+"=="+acc_public.name
    unless user.nil?
      #puts "ok_for_show? group:"+self.group.name+"=="+user.group.name
      (self.group_id==user.group.id || self.projowner.typeaccess_id==acc_public.id)
    else
      (self.projowner.typeaccess_id==acc_public.id)
    end
  end
  
  def before_destroy
    #unless Favori.get(self.model_name).count.zero?
    #  raise "Can't delete because of links:"+self.ident
    #end
    if Link.linked?(self)
      raise "Can't delete because of links:"+self.ident
    end
  end
  
end