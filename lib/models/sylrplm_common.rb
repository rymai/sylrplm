module Models::SylrplmCommon
  def self.included(base)
    # �a appelle extend du sous module ClassMethods sur "base", la classe dans laquelle tu as inclue la lib
    base.extend(ClassMethods)
  end

  module ClassMethods
    
    def get_object_controller(model_name)
      # ajouter le 's' de fin
      model_name+"s"
    end
   
    #
    # partie de requetes utilisees pour les filtres des objets (index)
    #
    
    # 
    def qry_projowner_typeaccess
      "(select typeaccess_id from projects as p where p.id = projowner_id)"
    end
    
    def qry_type
      "typesobject_id in (select id from typesobjects as t where t.name LIKE :v_filter)"
    end

    def qry_status
      "statusobject_id in (select id from statusobjects as s where s.name LIKE :v_filter)"
    end

    def qry_owner
      "owner in(select id from users where login LIKE :v_filter)"
    end

    def qry_responsible
      "responsible in(select id from users where login LIKE :v_filter)"
    end

    def qry_owner_id
      "owner_id in(select id from users where login LIKE :v_filter)"
    end

    def qrys_object_ident
      "object_id in(select id from documents where ident LIKE :v_filter)"
    end

    def qry_author
      "author in(select id from users where login LIKE :v_filter)"
    end

    def qry_volume
      "volume_id in(select id from volumes where name LIKE :v_filter)"
    end

    def qry_role
      "role_id in(select id from roles where title LIKE :v_filter)"
    end

    def qry_forum
      "forum_id in(select id from forums where subject LIKE :v_filter)"
    end

    def qry_parent
      "parent_id in(select id from forum_items where message LIKE :v_filter)"
    end

    def find_paginate(params)
      #puts self.model_name+"."+__method__.to_s+":"+params.inspect
      user=params[:user]
      filter_access={}
      filter_access[:values]={}
      mdl=eval self.model_name
      #puts self.model_name+"."+__method__.to_s+":"+self.column_names.inspect
      if column_names.include?(:projowner_id) 
        acc_public = ::Typesobject.find_by_object_and_name("project_typeaccess", "public")
        acc_confidential = ::Typesobject.find_by_object_and_name("project_typeaccess", "confidential") 
        filter_access[:qry] = ":v_acc_public_id="+qry_projowner_typeaccess+" or :v_acc_confidential_id="+qry_projowner_typeaccess 
        filter_access[:values][:v_acc_public_id] = acc_public.id
        filter_access[:values][:v_acc_confidential_id] = acc_confidential.id
      else
        filter_access[:qry] = ""
        filter_access[:values][:v_acc_public_id] = nil
        filter_access[:values][:v_acc_confidential_id] =nil
      end
      #puts self.model_name+"."+__method__.to_s+":"+filter_access[:qry].length.to_s
      unless user.nil? || !column_names.include?(:group_id) 
        filter_access[:qry] = " or " if filter_access[:qry].length > 0
        filter_access[:qry] += " group_id = :v_group_id"
        filter_access[:values][:v_group_id] = user.group.id
      end
      #puts self.model_name+".find_paginate:filter_access="+filter_access.inspect
      unless params[:query].nil? || params[:query]==""
        cond = get_conditions(params[:query])
        #puts self.model_name+".find_paginate:cond="+filter_access.inspect
        values=filter_access[:values].merge(cond[:values])
        conditions = [filter_access[:qry]+" and ("+cond[:qry] +")", values]
      else
        conditions = [filter_access[:qry], filter_access[:values]] 
      end
      #puts self.model_name+".find_paginate:conditions="+conditions.inspect
      recordset=self.paginate(:page => params[:page],
      :conditions => conditions,
      :order => params[:sort],
      :per_page => params[:nb_items])     
      {:recordset => recordset, :query => params[:query], :page => params[:page], :total => self.count(:conditions => conditions), :nb_items => params[:nb_items], :conditions => conditions}
    end
    
    def truncate_words(text, len = 5, end_string = " ...")
      return if text == nil
      words = text.split()
      words[0..(len-1)].join(' ') + (words.length > len ? end_string : '')
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
        #puts "sylrplm_common.set_default_values:"+strcol+"="+old_value.to_s+" to "+val.to_s
        self[strcol]=val
      end
    end
  end

  def model_name
    # Part devient part
   self.class.name.downcase
  end
  
  def controller_name
    # Part devient parts
   self.class.name.downcase+"s"
  end
  
  def get_object(type, id)
    # parts devient Part
    name=self.class.name+"."+__method__.to_s+":"
    #puts name+type.camelize+"."+id.to_s
    mdl=eval type.camelize
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
      mdl=get_model(lnk.father_plmtype)
      unless mdl.nil?
        f = mdl.find(lnk.father_id)
        p=f.get_path(lnk.relation.name)
        paths=f.follow_up(p)
        paths.each do |pp|
          ret<<path+pp
        end
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
  
  def get_model(model_name)
    begin
      ret=eval model_name.camelize
      rescue Exception => e
        LOG.warn("failed to find "+model_name+" : #{e}")
        ret=nil
      end
    ret
   end
  
  #
  # update the object accessor before update_attributes call
  #
  def update_accessor(user)
    self.owner_id = user.id if self.attribute_present?("owner_id")
    self.group_id = user.group_id if self.attribute_present?("group_id")
    self.projowner_id = user.project_id if self.attribute_present?("projowner_id")  
  end
  
  
end