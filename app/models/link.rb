class Link < ActiveRecord::Base
  include Models::SylrplmCommon
  #include Ruote::Sylrplm::ArWorkitem
  # une seule occurence d'un fils de type donne dans un pere de type donne
  ### verif par soft dans create_new validates_uniqueness_of :child_id, :scope => [:child_plmtype, :father_id, :father_type ]
  #validates_presence_of :name

  attr_accessor :user, :father, :child, :relation

  belongs_to :relation,
    :class_name => "Relation",
    :foreign_key => "relation_id"

  belongs_to :author,
    :class_name => "User"

  belongs_to :group

  belongs_to :projowner,
    :class_name => "Project"

  delegate :typesobject_id, :typesobject, to: :relation

  #objets pouvant etre fils:"document", "part", "project", "customer", "forum", "datafile"
  with_options :foreign_key => 'child_id' do |child|
    child.belongs_to :document , :conditions => ["child_plmtype='document'"], :class_name => "Document"
    child.belongs_to :part , :conditions => ["child_plmtype='part'"], :class_name => "Part"
    child.belongs_to :project , :conditions => ["child_plmtype='project'"], :class_name => "Project"
    child.belongs_to :customer , :conditions => ["child_plmtype='customer'"], :class_name => "Customer"
    child.belongs_to :forum , :conditions => ["child_plmtype='forum'"], :class_name => "Forum"
    child.belongs_to :datafile , :conditions => ["child_plmtype='datafile'"], :class_name => "Datafile"
  end

  #objets pouvant etre pere:"document", "part", "project", "customer", "definition", "history", "link"(pour les effectivites)
  with_options :foreign_key => 'father_id' do |father|
    father.belongs_to :document_up , :conditions => ["father_plmtype='document'"], :class_name => "Document"
    father.belongs_to :part_up , :conditions => ["father_plmtype='part'"], :class_name => "Part"
    father.belongs_to :project_up , :conditions => ["father_plmtype='project'"], :class_name => "Project"
    father.belongs_to :customer_up , :conditions => ["father_plmtype='customer'"], :class_name => "Customer"
    father.belongs_to :definition_up , :conditions => ["father_plmtype='definition'"], :class_name => "Definition"
    father.belongs_to :history_up , :conditions => ["father_plmtype='history_entry'"], :class_name => "Ruote::Sylrplm::HistoryEntry"
    father.belongs_to :link_up , :conditions => ["father_plmtype='link'"], :class_name => "Link"
  end

  has_many :links_effectivities ,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => ["father_plmtype='link' and child_plmtype='part' and child_typesobject_id in (select id from typesobjects as t where t.name='EFF')"]
  has_many :effectivities ,
    :through => :links_effectivities,
    :source => :part

  ###non validates_uniqueness_of :child_id, scope: [:child_plmtype, :father_id, :father_type]
  ###validates :link_uniqueness, :validity
  before_save :link_uniqueness, :validity

  # note sure what this does...
  def link_uniqueness
    cond = ["father_plmtype = ? and child_plmtype = ? and father_typesobject_id = ? and child_typesobject_id = ? and relation_id = ? ",
      father_plmtype, child_plmtype, father_typesobject_id, child_typesobject_id, relation_id]
    self.errors.add_to_base('Link already exists!') unless ::Link.find(:first, :conditions => cond).nil?
  end

  def validity
    fname = "#{self.class.name}.#{__method__}"
    begin

    #LOG.info(fname) {"father.typesobject=#{father.typesobject} relation.father_typesobject=#{relation.father_typesobject}"}
    #LOG.info(fname) {"child.typesobject=#{child.typesobject} relation.child_typesobject=#{relation.child_typesobject}"}
    ###valid = (father_plmtype == relation.father_plmtype || relation.father_plmtype == ::SYLRPLM::PLMTYPE_GENERIC) \
      valid = (father_plmtype == relation.father_plmtype) \
      && (child_plmtype == relation.child_plmtype || relation.child_plmtype == ::SYLRPLM::PLMTYPE_GENERIC) \
      && (father.typesobject.name==relation.father_typesobject.name || relation.father_typesobject.name == ::SYLRPLM::TYPE_GENERIC) \
      && (child.typesobject.name==relation.child_typesobject.name || relation.child_typesobject.name == ::SYLRPLM::TYPE_GENERIC)
      unless valid
        self.errors(:base).add('Link is not valid!')
        LOG.info(fname) {father.model_name+"=="+relation.father_plmtype + \
          " "+child.model_name+"=="+relation.child_plmtype + \
          " "+father.typesobject.name+"=="+relation.father_typesobject.name +  \
          " "+child.typesobject.name+"=="+relation.child_typesobject.name }
      end
    rescue Exception => e
      valid=false
      self.errors.add("Link not valid:father.typesobject=#{father.typesobject} relation.father_typesobject=#{relation.father_typesobject} child.typesobject=#{child.typesobject} relation.child_typesobject=#{relation.child_typesobject}")
    end
    valid
  end

  def cardinality_count
    nb_used = self.class.nb_used(relation)
    unless nb_used >= relation.cardin_use_min && (relation.cardin_use_max == -1 || nb_used <= relation.cardin_use_max)
      self.errors.add_to_base('Cardinality is not valid!')
    end
  end

  def user=(user)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug (fname) {"user=#{user.inspect}"}
    #on accepte sans user (voir workitems_controller)
    unless user.nil?
    self.author    = user
    self.group     = user.group
    self.projowner = user.project
    end
  end

  def father=(father)
    self.father_plmtype        = father.model_name
    self.father_typesobject_id = father.typesobject_id
    self.father_id             = father.id
  end

  def father
    get_object(father_plmtype, father_id)
  end

  def father_ident
    ret  = "#{father_id}:#{father_plmtype}.#{father_typesobject_id}"
    ret += "=#{father.ident}" unless father.nil?
  end

  def child=(child)
    self.child_plmtype        = child.model_name
    self.child_typesobject_id = child.typesobject_id
    self.child_id             = child.id
  end

  def child
    get_object(child_plmtype, child_id)
  end

  def child_ident
    ret  = "#{child_id}:#{child_plmtype}.#{child_typesobject_id}"
    ret += "=#{child.ident}" unless child.nil?
  end

  def relation=(relation)
    #TODO pour eviter super: no superclass method `relation=' for #<Link:0x9aceec4> super
    self.values = relation.typesobject.fields
    self.relation_id = relation.id
  end

  def relation_ident
    begin
      rel = Relation.find(self.relation_id) unless self.relation_id.nil?
      relation_id.to_s + (rel.ident unless rel.nil?)
    rescue
      relation_id.to_s
    end
  end

  def ident
    "#{(father.nil? ? "father null" : father.ident)}-#{(relation.nil? ? "relation null" : relation.ident)}-#{(child.nil? ? "child null" : child.ident)}-#{values}"
  end

  def effectivities_mdlid
    @effectivities_mdlid ||= effectivities.map(&:mdlid)
  end

  #menage des effectivites non presentes dans effs_mdlid: [part.24, part.22]
  def clean_effectivities(effectivities_mdlids)
    fname = "#{self.class.name}.#{__method__}"
    LOG.info (fname) { "effectivities_mdlids: #{effectivities_mdlids}" }
    links_effectivities.each do |current_link_effectivity|
      LOG.info (fname) { "current_link_effectivity=#{current_link_effectivity.ident} : #{current_link_effectivity.child.mdlid}" }
      unless effectivities_mdlids.include?(current_link_effectivity.child.mdlid)
        LOG.info (fname) { "destroy:#{current_link_effectivity.ident}" }
      current_link_effectivity.destroy
      end
    end
  end

  def after_find
    fname= "#{self.class.name}.#{__method__}"
    rel=self.relation
    unless rel.nil?
      if self.values.nil?
        fields = rel.typesobject.fields
        self.values = fields unless fields.nil?
        LOG.info (fname) {"#{fields} : #{self.values}"}
      end
    end
  end

  def type
    "link"
  end

  # creation
  def self.create_new(father, child, relation, user)
    raise Exception.new "Don't use this method"
  end

  # link creation with values
  # calls from PLMParticipant
  def self.create_new_by_values(values, user = nil)
    raise Exception.new "Don't use this method"
  end

  def exists?
    raise Exception.new "Don't use this method"
  end

  # bidouille infame car l'association ne marche pas
  def relation
    begin
      Relation.find(relation_id)
    rescue Exception => e
      fname= "#{self.class.name}.#{__method__}"
      LOG.error (fname) {"relation not found:#{e}"}
      nil
    end
  end

  def relation_name
    (self.relation.nil? ? "nil" : self.relation.name )
  end

  def self.valid?(father, child, relation)
    raise Exception.new "Don't use this method"
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

  def self.find_childs(father, child_plmtype=nil, relation_name=nil)
    find_childs_with_father_plmtype(father.model_name, father, child_plmtype, relation_name)
  end

  def self.find_childs_with_father_plmtype(father_plmtype, father, child_plmtype=nil, relation_name=nil)
    unless child_plmtype.nil?
      cond="father_plmtype='#{father_plmtype}' and child_plmtype='#{child_plmtype}' and father_id =#{father.id}"
    else
      cond="father_plmtype='#{father_plmtype}' and father_id =#{father.id}"
    end
    links = Link.find(:all,
    :conditions => [cond],
    :order=>"child_id DESC")
    unless relation_name.nil?
      ret=[]
      links.each do |lnk|
        ret<<lnk unless lnk.relation.name==relation_name
      end
    else
    ret=links
    end
    #puts "Link.find_childs_with_father_plmtype:"+father.model_name+"."+father.id.to_s+"."+child_plmtype+":'"+cond+"'= "+ret.inspect
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

  def self.find_by_father_plmtype_(plmtype)
    name=self.class.name+"."+__method__.to_s+":"
    #puts name+plmtype
    find(:all,
    :conditions => ["father_plmtype='#{plmtype}'"],
    :order=>"father_id DESC , child_id DESC")
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
    :conditions => ["relations.father_plmtype = ? and relations.child_plmtype= ? and relations.child_typesobject_id = ? and father_id = ?",
      relation.father_plmtype, relation.child_plmtype, relation.child_typesobject_id, father.id ]
    )
    ret = links.count unless links.nil?
    ret
  end

  def self.nb_used(relation)
    ret=0
    puts "Link.nb_used:"+relation.child_plmtype+":"+relation.child_typesobject_id.to_s
    links = find(:all, :include => :relation, :conditions => ["relations.child_plmtype = ? and relations.child_typesobject_id = ?", relation.child_plmtype, relation.child_typesobject_id])
    ret = links.count unless links.nil?
    ret
  end

  def self.get_conditions(filter)
    nil
  end

  def self.linked?(obj)
    cond="(child_typesobject_id=#{obj.typesobject_id} and child_id = #{obj.id}) or (father_typesobject_id=#{obj.typesobject_id} and father_id = #{obj.id})"
    ret = count(:all,
    :conditions => [cond] )
    puts "linked cond=#{cond} nb=#{ret}"
    ret>0
  end
end
