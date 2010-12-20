
module Models::SylrplmCommon
  def self.included(base)
    base.extend(ClassMethods) # ça appelle extend du sous module ClassMethods sur "base", la classe dans laquelle tu as inclue la lib
  end
  
  module ClassMethods
    
    #utilise pour les filtres des objets (index)
    def qry_type
    "typesobject_id in(select id from typesobjects as t where t.name LIKE ?)"
    end
    def qry_status
    "statusobject_id in (select id from statusobjects as s where s.name LIKE ?)"
    end
    def qry_owner
    "owner in(select id from users where login LIKE ?)"
    end
    def qry_owner_id
    "owner_id in(select id from users where login LIKE ?)"
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
    
    # attribution de valeurs par defaut suivant la table sequence
    def set_default_values(next_seq)
      #find_cols_for(model).each do |strcol|
      # object.column_for_attribute(strcol)=
      #get_constants
      self.attribute_names().each do |strcol|
        old_value=self[strcol]
        #col=self.find_col_for(strcol)
        col=Sequence.find_col_for(self.class.name,strcol)
        val=old_value
        if(col!=nil) 
          if(col.sequence==true)
            if(next_seq==true)
              val=Sequence.get_next_seq(col.utility)
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
end