class Link < ActiveRecord::Base
  include Models::SylrplmCommon

  # une seule occurence d'un fils de type donne dans un pere de type donne
  ### verif par soft dans create_new validates_uniqueness_of :child_id, :scope => [:child_type, :father_id, :father_type ]
  #validates_presence_of :name
  with_options :foreign_key => 'child_id' do |relation|
    relation.belongs_to :document , :conditions => ["child_type='document'"]
    relation.belongs_to :part , :conditions => ["child_type='part'"]
    relation.belongs_to :project , :conditions => ["child_type='project'"]
    relation.belongs_to :customer , :conditions => ["child_type='customer'"]
    relation.belongs_to :datafiles , :conditions => ["child_type='datafile'"]
    relation.belongs_to :workitems , :conditions => ["child_type='workitem'"]
    relation.belongs_to :histories , :conditions => ["child_type='history'"]
  end

  def self.create_new_byid(father_type, father, child_type, child, relation)
    ok=false
    msg="ctrl_link_"+father_type.to_s+"_"+child_type.to_s
    if(father_type.to_s=="customer" && child_type.to_s=="project")
      ok=true
      if(is_child_of(father_type.to_s, father, child_type.to_s, child))
        ok=false
        msg=:ctrl_link_already_customer_project.to_s
      elsif(nb_linked(child_type, child)>0)
        ok=false
        msg=:ctrl_link_already_project.to_s
      end
    end
    if(father_type.to_s=="customer" && child_type.to_s=="document")
      ok=true
      if(is_child_of(father_type.to_s, father, child_type.to_s, child))
        ok=false
        msg=:ctrl_link_already_customer_document.to_s
      end
    end
    if(father_type.to_s=="document" && child_type.to_s=="document")
      ok=true
    end
    if(father_type.to_s=="project" && child_type.to_s=="part")
      ok=true

    end
    if(father_type.to_s=="project" && child_type.to_s=="user")
      ok=true
      if(is_child_of(father_type.to_s, father, child_type.to_s, child))
        ok=false
        msg=:ctrl_link_already_project_user.to_s
      end
    end
    if(father_type=="project" && child_type=="document")
      ok=true
      if(is_child_of(father_type.to_s, father, child_type.to_s, child))
        ok=false
        msg=:ctrl_link_already_project_document.to_s
      end
    end
    if(father_type.to_s=="part" && child_type.to_s=="part")
      ok=true
      if(father==child)
        ok=false
        msg=:ctrl_link_recursivity.to_s
      end
    end
    if(father_type.to_s=="part" && child_type.to_s=="document")
      ok=true
      if(is_child_of(father_type.to_s, father, child_type.to_s, child))
        ok=false
        msg=:ctrl_link_already_part_document.to_s
      end
    end
    if(father_type.to_s=="workitem" && child_type.to_s=="document")
      ok=true
      if(is_child_of(father_type.to_s, father, child_type.to_s, child))
        ok=false
        msg=:ctrl_link_already_workitem_document.to_s
      end
    end
    if(father_type.to_s=="workitem" && child_type.to_s=="part")
      ok=true
      if(is_child_of(father_type.to_s, father, child_type.to_s, child))
        ok=false
        msg=:ctrl_link_already_workitem_part.to_s
      end
    end
    if(child_type=="forum")
      ok=true
    end
    if(child_type=="datafile")
      ok=true
    end
    link=nil
    if(ok==true)
      link = Link.new
      link.father_type=father_type.to_s
      link.child_type=child_type.to_s
      link.father_id=father
      link.child_id=child
      link.name=relation
    end
    puts "link:create_new:link="+link.inspect+" msg="+msg.to_s
    {:link=>link,:msg=>msg}
  end

  def self.create_new(father_type, father, child_type, child, relation)
    create_new_byid(father_type, father.id, child_type, child.id, relation)
  end

  #  def before_save
  #    puts "link.before_save:"+self.inspect
  #    # ##self.child_type=self.child.class.to_s.underscore
  #    self.name=self.child.link_attributes[:name]
  #    puts "link.before_save:"+self.inspect
  #    self
  #  end

  #  def child
  #    child_cls=eval(self.child_type.capitalize)
  #    #puts "link.child:classe="+child_cls.inspect
  #    c=child_cls.new(self.child_id)
  #  end

  def self.find_childs(father_type, father, child_type=nil)
    unless child_type.nil?
      find(:all,
      :conditions => ["father_type='#{father_type}' and child_type='#{child_type}' and father_id =#{father.id}"],
      :order=>"child_id")
    else
      find(:all,
      :conditions => ["father_type='#{father_type}' and father_id =#{father.id}"],
      :order=>"child_id")
    end
  end

  def self.find_child(father_type, father, child_type, child)
    find(:first,
    :conditions => ["father_type='#{father_type}' and child_type='#{child_type}' and father_id =#{father.id} and child_id =#{child.id}"],
    :order=>"child_id")
  end

  def self.find_fathers(child_type, child, father_type)
    find(:all,
    :conditions => ["father_type='#{father_type}' and child_type='#{child_type}' and child_id =#{child.id}"],
    :order=>"child_id")
  end

  def self.is_child_of(father_type, father, child_type, child)
    ret=false
    childs=find_childs(father_type, father, child_type)
    nb=find(:all,
    :conditions => ["father_type='#{father_type}'
      and child_type='#{child_type}'
      and father_id =#{father} and child_id=#{child}"]
    ).count
    ret=nb>0
  end

  def self.nb_linked(child_type, child)
    ret=0
    links=find(:all,
    :conditions => ["child_type='#{child_type}' and child_id =#{child.id}"] )
    if(links!=nil)
      ret=links.count
    end
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
