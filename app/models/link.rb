class Link < ActiveRecord::Base
  include Models::SylrplmCommon

  # une seule occurence d'un fils de type donne dans un pere de type donne
  ### verif par soft dans create_new validates_uniqueness_of :child_id, :scope => [:child_object, :father_id, :father_object ]

  with_options :foreign_key => 'child_id' do |relation|
    relation.belongs_to :document , :conditions => ["child_object='document'"]
    relation.belongs_to :part , :conditions => ["child_object='part'"]
    relation.belongs_to :project , :conditions => ["child_object='project'"]
    relation.belongs_to :customer , :conditions => ["child_object='customer'"]
    relation.belongs_to :datafiles , :conditions => ["child_object='datafile'"]
    relation.belongs_to :workitems , :conditions => ["child_object='workitem'"]
  end

  def self.find_childs(father_object, father, child_object=nil)
    unless child_object.nil?
      find(:all,
      :conditions => ["father_object='#{father_object}' and child_object='#{child_object}' and father_id =#{father.id}"],
      :order=>"child_id")
    else
      find(:all,
      :conditions => ["father_object='#{father_object}' and father_id =#{father.id}"],
      :order=>"child_id")
    end
  end

  def self.find_child(father_object, father, child_object, child)
    find(:first,
    :conditions => ["father_object='#{father_object}' and child_object='#{child_object}' and father_id =#{father.id} and child_id =#{child.id}"],
    :order=>"child_id")
  end

  def self.find_fathers(child_object, child, father_object)
    find(:all,
    :conditions => ["father_object='#{father_object}' and child_object='#{child_object}' and child_id =#{child.id}"],
    :order=>"child_id")
  end

  def self.is_child_of(father_object, father, child_object, child)
    ret=false
    childs=find_childs(father_object, father, child_object)
    nb=find(:all,
    :conditions => ["father_object='#{father_object}'
      and child_object='#{child_object}'
      and father_id =#{father} and child_id=#{child}"]
    ).count
    ret=nb>0
  end

  def self.nb_linked(child_object, child)
    ret=0
    links=find(:all,
    :conditions => ["child_object='#{child_object}' and child_id =#{child.id}"] )
    if(links!=nil)
      ret=links.count
    end
    ret
  end

  def self.create_new_byid(father_object, father, child_object, child, relation)
    ok=false
    msg="ctrl_link_"+father_object.to_s+"_"+child_object.to_s
    if(father_object.to_s=="customer" && child_object.to_s=="project")
      ok=true
      if(is_child_of(father_object.to_s, father, child_object.to_s, child))
        ok=false
        msg=:ctrl_link_already_customer_project.to_s
      elsif(nb_linked(child_object, child)>0)
        ok=false
        msg=:ctrl_link_already_project.to_s
      end
    end
    if(father_object.to_s=="customer" && child_object.to_s=="document")
      ok=true
      if(is_child_of(father_object.to_s, father, child_object.to_s, child))
        ok=false
        msg=:ctrl_link_already_customer_document.to_s
      end
    end
    if(father_object.to_s=="project" && child_object.to_s=="part")
      ok=true
    end
    if(father_object=="project" && child_object=="document")
      ok=true
      if(is_child_of(father_object.to_s, father, child_object.to_s, child))
        ok=false
        msg=:ctrl_link_already_project_document.to_s
      end
    end
    if(father_object.to_s=="part" && child_object.to_s=="part")
      ok=true
      if(father==child)
        ok=false
        msg=:ctrl_link_recursivity.to_s
      end
    end
    if(father_object.to_s=="part" && child_object.to_s=="document")
      ok=true
      if(is_child_of(father_object.to_s, father, child_object.to_s, child))
        ok=false
        msg=:ctrl_link_already_part_document.to_s
      end
    end
    if(father_object.to_s=="workitem" && child_object.to_s=="document")
      ok=true
      if(is_child_of(father_object.to_s, father, child_object.to_s, child))
        ok=false
        msg=:ctrl_link_already_workitem_document.to_s
      end
    end
    if(father_object.to_s=="workitem" && child_object.to_s=="part")
      ok=true
      if(is_child_of(father_object.to_s, father, child_object.to_s, child))
        ok=false
        msg=:ctrl_link_already_workitem_part.to_s
      end
    end
    if(child_object=="forum")
      ok=true
    end
    if(child_object=="datafile")
      ok=true
    end
    link=nil
    if(ok==true)
      link = Link.new
      link.father_object=father_object.to_s
      link.child_object=child_object.to_s
      link.father_id=father
      link.child_id=child
      link.name=relation
    end
    puts "link:create_new:link="+link.inspect+" msg="+msg.to_s
    {:link=>link,:msg=>msg}
  end

  def self.create_new(father_object, father, child_object, child, relation)
    create_new_byid(father_object, father.id, child_object, child.id, relation)
  end

  def self.create_new_old(father_object, father, child_object, child, relation)
    ok=false
    msg="ctrl_link_"+father_object.to_s+"_"+child_object.to_s
    if(father_object.to_s=="customer" && child_object.to_s=="project")
      ok=true
      if(is_child_of(father_object.to_s, father, child_object.to_s, child))
        ok=false
        msg=:ctrl_link_already_customer_project.to_s
      elsif(nb_linked(child_object, child)>0)
        ok=false
        msg=:ctrl_link_already_project.to_s
      end
    end
    if(father_object.to_s=="customer" && child_object.to_s=="document")
      ok=true
      if(is_child_of(father_object.to_s, father, child_object.to_s, child))
        ok=false
        msg=:ctrl_link_already_customer_document.to_s
      end
    end
    if(father_object.to_s=="project" && child_object.to_s=="part")
      ok=true
    end
    if(father_object=="project" && child_object=="document")
      ok=true
      if(is_child_of(father_object.to_s, father, child_object.to_s, child))
        ok=false
        msg=:ctrl_link_already_project_document.to_s
      end
    end
    if(father_object.to_s=="part" && child_object.to_s=="part")
      ok=true
      if(father==child)
        ok=false
        msg=:ctrl_link_recursivity.to_s
      end
    end
    if(father_object.to_s=="part" && child_object.to_s=="document")
      ok=true
      if(is_child_of(father_object.to_s, father, child_object.to_s, child))
        ok=false
        msg=:ctrl_link_already_part_document.to_s
      end
    end
    if(father_object.to_s=="workitem" && child_object.to_s=="document")
      ok=true
      if(is_child_of(father_object.to_s, father, child_object.to_s, child))
        ok=false
        msg=:ctrl_link_already_workitem_document.to_s
      end
    end
    if(father_object.to_s=="workitem" && child_object.to_s=="part")
      ok=true
      if(is_child_of(father_object.to_s, father, child_object.to_s, child))
        ok=false
        msg=:ctrl_link_already_workitem_part.to_s
      end
    end
    if(child_object=="forum")
      ok=true
    end
    if(child_object=="datafile")
      ok=true
    end
    link=nil
    if(ok==true)
      link = Link.new
      link.father_object=father_object.to_s
      link.child_object=child_object.to_s
      link.father_id=father.id
      link.child_id=child.id
      link.name=relation
    end
    puts "link:create_new:link="+link.inspect+" msg="+msg.to_s
    {:link=>link,:msg=>msg}
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
