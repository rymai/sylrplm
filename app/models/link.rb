class Link < ActiveRecord::Base
  include Models::SylrplmCommon
  # une seule occurence d'un fils de type donne dans un pere de type donne
  ### verif par soft dans create_new validates_uniqueness_of :child_id, :scope => [:child_plmtype, :father_id, :father_type ]
  #validates_presence_of :name

  belongs_to :relation

  belongs_to :owner,
    :class_name => "User"

  belongs_to :group

  belongs_to :projowner,
    :class_name => "Project"
      
  #objets pouvant etre relies:"document", "part", "project", "customer", "forum", "definition", "datafile", "relation", "user", "ar_workitem", "history"
  with_options :foreign_key => 'child_id' do |child|
    child.belongs_to :document , :conditions => ["child_plmtype='document'"], :class_name => "Document"
    child.belongs_to :part , :conditions => ["child_plmtype='part'"], :class_name => "Part"
    child.belongs_to :project , :conditions => ["child_plmtype='project'"], :class_name => "Project"
    child.belongs_to :customer , :conditions => ["child_plmtype='customer'"], :class_name => "Customer"
    child.belongs_to :forum , :conditions => ["child_plmtype='forum'"], :class_name => "Forum"
    child.belongs_to :definition , :conditions => ["child_plmtype='definition'"], :class_name => "Definition"
    child.belongs_to :datafile , :conditions => ["child_plmtype='datafile'"], :class_name => "Datafile"
    child.belongs_to :relation , :conditions => ["child_plmtype='relation'"], :class_name => "Relation"
    child.belongs_to :user , :conditions => ["child_plmtype='user'"], :class_name => "User"
    child.belongs_to :ar_workitem , :conditions => ["child_plmtype='ar_workitem'"], :class_name => "ArWorkitem"
    child.belongs_to :history , :conditions => ["child_plmtype='history'"], :class_name => "HistoryEntry"
  end

  def father
    get_object(father_plmtype, father_id)
  end

  def child
    get_object(child_plmtype, child_id)
  end

  def ident
    father_plmtype+"."+father_type_id.to_s+"-"+Relation.find(relation_id).ident+"-"+child_plmtype+"."+child_type_id.to_s
  end

  def relation_name
    (self.relation ? self.relation.name : "")
  end

  def self.valid?(father, child, relation)
    name= "Link."+__method__.to_s+":"
    ret=(father.model_name==relation.father_plmtype || relation.father_plmtype == ::SYLRPLM::PLMTYPE_GENERIC) \
    && (child.model_name==relation.child_plmtype || relation.child_plmtype == ::SYLRPLM::PLMTYPE_GENERIC) \
    && (father.typesobject.name==relation.father_type.name || relation.father_type.name == ::SYLRPLM::TYPE_GENERIC) \
    && (child.typesobject.name==relation.child_type.name || relation.child_type.name == ::SYLRPLM::TYPE_GENERIC)
    if ret==false
      puts name+father.model_name+"=="+relation.father_plmtype + \
      " "+child.model_name+"=="+relation.child_plmtype + \
      " "+father.typesobject.ident+"=="+relation.id.to_s+"."+relation.father_type.ident + \
      " "+child.typesobject.ident+"=="+relation.child_type.ident
    end
    ret
  end

  def self.create_new_by_values(values)
    link = Link.new(values)
    link.owner=current_user
    link.group=current_user.group
    msg="ctrl_link_"+link.ident
    ret={:link => link,:msg => msg}
    #puts "link.create_new_by_values:"+ret.inspect
    ret
  end

  def self.create_new(father, child, relation, user)
    #puts "link:create_new:"+father.inspect+"-"+child.inspect+"."+child.inspect
    if valid?(father, child, relation)
      nbused = self.nb_used(relation)
      nboccured = self.nb_occured(father, relation)
      #puts "link.create_new:"+nbused.to_s+ " "+child.model_name+"."+child.typesobject.name+" utilises dans relation "+relation.ident
      #puts "link.create_new:"+nboccured.to_s+ " "+child.model_name+"."+child.typesobject.name+" occurences "+" dans "+father.ident
      if (nbused >= relation.cardin_use_min && (relation.cardin_use_max == -1 || nbused <= relation.cardin_use_max))
        obj = Link.new
        obj.father_plmtype = father.model_name
        obj.child_plmtype = child.model_name
        obj.father_type_id = father.typesobject_id
        obj.child_type_id = child.typesobject_id
        obj.father_id = father.id
        obj.child_id = child.id
        obj.relation_id = relation.id
        obj.owner=user
        obj.group=user.group
        obj.projowner=user.project
        msg="ctrl_link_"+obj.ident
      else
        obj=nil
        msg=:ctrl_link_too_many_used
      end
    else
      obj=nil
      msg=:ctrl_link_not_valid
    end
    ret={:link => obj,:msg => msg}
    #puts "link.create_new:"+ret.inspect
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
    #puts name+child_plmtype+" cond="+cond+":"+ret.inspect
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
