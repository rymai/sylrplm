module Models::SylrplmCommon
  def self.included(base)
    # �a appelle extend du sous module ClassMethods sur "base", la classe dans laquelle tu as inclue la lib
    base.extend(ClassMethods)
  end

  module ClassMethods
    def get_object_controller(model_type)
      # ajouter le 's' de fin
      model_type+"s"
    end
    
   
    
    #utilise pour les filtres des objets (index)
    def qry_type
      "typesobject_id in (select id from typesobjects as t where t.name LIKE ?)"
    end

    def qry_status
      "statusobject_id in (select id from statusobjects as s where s.name LIKE ?)"
    end

    def qry_owner
      "owner in(select id from users where login LIKE ?)"
    end

    def qry_responsible
      "responsible in(select id from users where login LIKE ?)"
    end

    def qry_owner_id
      "owner_id in(select id from users where login LIKE ?)"
    end

    def qrys_object_ident
      "object_id in(select id from documents where ident LIKE ?)"
    end

    def qry_author
      "author in(select id from users where login LIKE ?)"
    end

    def qry_volume
      "volume_id in(select id from volumes where name LIKE ?)"
    end

    def qry_role
      "role_id in(select id from roles where title LIKE ?)"
    end

    def qry_forum
      "forum_id in(select id from forums where subject LIKE ?)"
    end

    def qry_parent
      "parent_id in(select id from forum_items where message LIKE ?)"
    end

    def find_paginate(params)
      if params[:query].nil? || params[:query]==""
        conditions=nil
      else
        conditions=get_conditions(params[:query])
      end
      recordset=self.paginate(:page => params[:page],
      :conditions => conditions,
      :order => params[:sort],
      :per_page => params[:nb_items])
      {:recordset=>recordset, :query=>params[:query], :page => params[:page], :total=>self.count(:conditions=>conditions), :nb_items=>params[:nb_items], :conditions=>conditions}
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
      col = ::Sequence.find_col_for(self.class.name,strcol)
      val=old_value
      if(col!=nil)
        if(col.sequence==true)
          if(next_seq==true)
            val = ::Sequence.get_next_seq(col.utility)
          end
        else
          val=col.value
        end
        puts "sylrplm_common.set_default_values:"+strcol+"="+old_value.to_s+" to "+val.to_s
        #object.update_attribute(strcol,val)
        self[strcol]=val
      end
    end
  end
  
  # renvoie le type de l'objet: nom de la classe en minuscule
     #TODO compatibilite
    #def object_type
    # Part devient part
    # model_name
    #end

  def model_name()
    # Part devient part
    self.class.name.downcase
  end
  
  def get_object(type, id)
    # parts devient Part
    name=self.class.name+"."+__method__.to_s+":"
    puts name+type+"."+id.to_s
    mdl=eval type.capitalize
    begin
    ret=mdl.find(id)
    rescue Exception => e
      LOG.warn("failed to find "+type+"."+id.to_s+" : #{e}")
      ret=nil
    end
    ret
  end
  
   def follow_up(path)
    name=self.class.name+"."+__method__.to_s+":"
    #puts name+path
    ret=[]
    if path.nil?
      path=get_path
    end
    links=Link.get_all_fathers(self)    
    links.each do |lnk|
      f = get_model(lnk.father_type).find(lnk.father_id)
      p=f.get_path(lnk.name)
      paths=f.follow_up(p)
      paths.each do |pp|
        ret<<path+pp
      end
    end
    if ret.count==0
      ret<<path
    end
    #puts name+"end ret="+ret.inspect
    ret
  end  
  
  def get_path(relation=nil)
    unless relation.nil?
      ret="#"+relation+":"+self.model_name+"."+self.ident
    else
      # debut de branche
      ret="$"+self.model_name+"."+self.ident
    end
    ret
  end
  
   def get_model(model_type)
      eval model_type.capitalize
    end
  
end