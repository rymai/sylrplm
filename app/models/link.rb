class Link < ActiveRecord::Base
  include Models::SylrplmCommon
  # une seule occurence d'un fils de type donne dans un pere de type donne
  ### verif par soft dans create_new validates_uniqueness_of :child_id, :scope => [:child_plmtype, :father_id, :father_type ]
  #validates_presence_of :name

  belongs_to :relation

  with_options :foreign_key => 'child_id' do |child|
    child.belongs_to :document , :conditions => ["child_plmtype='document'"], :class_name => "Document"
    child.belongs_to :part , :conditions => ["child_plmtype='part'"], :class_name => "Part"
    child.belongs_to :project , :conditions => ["child_plmtype='project'"], :class_name => "Project"
    child.belongs_to :customer , :conditions => ["child_plmtype='customer'"], :class_name => "Customer"
    child.belongs_to :datafile , :conditions => ["child_plmtype='datafile'"], :class_name => "Datafile"
    child.belongs_to :workitem , :conditions => ["child_plmtype='workitem'"], :class_name => "Workitem"
    child.belongs_to :history , :conditions => ["child_plmtype='history'"], :class_name => "HistoryEntry"
  end

  def ident
    father_plmtype+"."+father_type_id.to_s+"-"+Relation.find(relation_id).ident+"-"+child_plmtype+"."+child_type_id.to_s
  end
  
  def relation_name
    (self.relation ? self.relation.name : "")
  end
  
  def self.isvalid(father, child, relation)
    father.model_name==relation.father_plmtype \
    && child.model_name==relation.child_plmtype \
    && father.typesobject.name==relation.father_type.name \
    && child.typesobject.name==relation.child_type.name
  end
  
  def self.create_new_by_values(values)
    link = Link.new(values)
    msg="ctrl_link_"+link.ident
    ret={:link => link,:msg => msg}
    puts "link:create_new_by_values:"+ret.inspect
    ret
  end
  
  def self.create_new(father, child, relation)
    #puts "link:create_new:"+father.inspect+"-"+child.inspect+"."+child.inspect
    if isvalid(father, child, relation)
      nbused = self.nb_used(relation)
      nboccured = self.nb_occured(father, relation)
      puts "link:create_new:"+nbused.to_s+ " "+child.model_name+"."+child.typesobject.name+" utilises dans relation "+relation.ident
      puts "link:create_new:"+nboccured.to_s+ " "+child.model_name+"."+child.typesobject.name+" occurences "+" dans "+father.ident
      if (nbused >= relation.cardin_use_min && (relation.cardin_use_max == -1 || nbused <= relation.cardin_use_max))
        link = Link.new
        link.father_plmtype = father.model_name
        link.child_plmtype = child.model_name
        link.father_type_id = father.typesobject_id
        link.child_type_id = child.typesobject_id
        link.father_id = father.id
        link.child_id = child.id
        link.relation_id = relation.id
        msg="ctrl_link_"+link.ident
      else
        link=nil
        msg=:ctrl_link_too_many_used
      end
    else
      link=nil
      msg=:ctrl_link_not_valid
      puts __FILE__+"."+__method__.to_s+":"+father.model_name+"=="+relation.father_plmtype + \
      " "+child.model_name+"=="+relation.child_plmtype + \
      " "+father.typesobject.to_s+"=="+relation.father_type.to_s + \
      " "+child.typesobject.to_s+"=="+relation.child_type.to_s

    end 
    ret={:link => link,:msg => msg}
    puts "link:create_new:"+ret.inspect
    ret
  end
  
  #  def before_save
  #    puts "link.before_save:"+self.inspect
  #    # ##self.child_plmtype=self.child.class.to_s.underscore
  #    self.name=self.child.link_attributes[:name]
  #    puts "link.before_save:"+self.inspect
  #    self
  #  end

  #  def child
  #    child_cls=eval(self.child_plmtype.capitalize)
  #    #puts "link.child:classe="+child_cls.inspect
  #    c=child_cls.new(self.child_id)
  #  end

  def self.find_childs(father, child_plmtype=nil)
    find_childs_with_father_type(father.model_name, father, child_plmtype)
  end
  
  def self.find_childs_with_father_type(father_type, father, child_plmtype=nil)
   ret= unless child_plmtype.nil?
      find(:all,
      :conditions => ["father_plmtype='#{father_type}' and child_plmtype='#{child_plmtype}' and father_id =#{father.id}"],
      :order=>"child_id")
    else
      find(:all,
      :conditions => ["father_plmtype='#{father_type}' and father_id =#{father.id}"],
      :order=>"child_id")
    end
    #puts "Link.find_childs_with_father_type:"+father_type+":"+father.model_name+"."+father.id.to_s+"="+ret.inspect
    ret
  end

  def self.find_child(father_plmtype, father, child_plmtype, child)
    find(:first,
    :conditions => ["father_plmtype='#{father_plmtype}' and child_plmtype='#{child_plmtype}' and father_id =#{father.id} and child_id =#{child.id}"],
    :order=>"child_id")
  end

  def self.find_fathers(child_plmtype, child, father_plmtype)
    find(:all,
    :conditions => ["father_plmtype='#{father_plmtype}' and child_plmtype='#{child_plmtype}' and child_id =#{child.id}"],
    :order=>"child_id")
  end

  def self.get_all_fathers(child)
    name=self.class.name+"."+__method__.to_s+":"
    child_plmtype=child.model_name
    cond="child_plmtype='#{child_plmtype}' and child_id =#{child.id}"
    ret=find(:all,
    :conditions => [cond],
    :order=>"child_id")
    puts name+child_plmtype+" cond="+cond+":"+ret.inspect
    ret
  end

  def self.is_child_of(father_plmtype, father, child_plmtype, child)
    ret=false
    #childs=find_childs(father_type, father, child_plmtype)
    nb=find(:all,
    :conditions => ["father_plmtype='#{father_plmtype}' and child_plmtype='#{child_plmtype}' and father_id =#{father} and child_id=#{child}"]
    ).count
    ret=nb>0
  end

  def self.nb_linked(child_plmtype, child)
    ret=0
    links = find(:all,
    :conditions => ["child_plmtype='#{child_plmtype}' and child_id =#{child}"] )
    ret = links.count unless links.nil?
    ret
  end

  def self.nb_occured(father, relation)
    ret=0
    links = find(:all, :include => :relation,
    :conditions => ["relations.father_plmtype = ? and relations.child_plmtype= ? and relations.child_type_id = ? and father_id = ?",
      relation.father_plmtype, relation.child_plmtype, relation.child_type_id, father.id ]
    )
    ret = links.count unless links.nil?
    ret
  end

  def self.nb_used(relation)
    ret=0
    links = find(:all, :include => :relation, :conditions => ["relations.child_plmtype = ? and relations.child_type_id = ?", relation.child_plmtype, relation.child_type_id])
    ret = links.count unless links.nil?
    ret
  end

  def self.remove(id)
    link=self.find(id)
    link.destroy
    nil
  end

  def self.get_conditions(filter)
    nil
  end
  
  
  
end
