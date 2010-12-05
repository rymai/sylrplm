
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
    
  end
end