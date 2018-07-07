# frozen_string_literal: true

class Link < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon
  # une seule occurence d'un fils de type donne dans un pere de type donne
  ### verif par soft dans create_new validates_uniqueness_of :child_id, :scope => [:child_plmtype, :father_id, :father_type ]
  # validates_presence_of :name

  attr_accessor :user
  attr_accessible :id, :father_plmtype, :child_plmtype, :father_id, :child_id, :relation_id, :type_values
  attr_accessible :owner_id, :group_id, :projowner_id, :domain

  belongs_to :relation,
             class_name: 'Relation',
             foreign_key: 'relation_id'

  belongs_to :owner,
             class_name: 'User'

  belongs_to :group

  belongs_to :projowner,
             class_name: 'Project'

  NO_CHILD = '-NO_CHILD-'
  NO_FATHER = '-NO_FATHER-'

  LINKNAME_LINK_EFF = 'LINK_EFF'
  # delegate :typesobject_id, :typesobject, to: :relation

  # objects which could be child of link: "document", "part", "project", "customer", "forum", "datafile"
  with_options foreign_key: 'child_id' do |child|
    # child.belongs_to :document_down, -> { where(child_plmtype: 'document'  ) } ,		:class_name => "Document"
    child.belongs_to :document_down,	class_name: 'Document'
    child.belongs_to :part_down,	class_name: 'Part'
    child.belongs_to :project_down,	class_name: 'Project'
    child.belongs_to :customer_down,	class_name: 'Customer'
    child.belongs_to :forum_down,	class_name: 'Forum'
    child.belongs_to :datafile_down,				class_name: 'Datafile'
    # child.belongs_to :effectivity_down , -> { where("child_plmtype = 'part' and parts.typesobject_id in (select id from typesobjects where name='EFF')") },		:class_name => "Part"
    # child.belongs_to :variant_down , -> { where("child_plmtype = 'part' and parts.typesobject_id in (select id from typesobjects where name='VAR')") },		:class_name => "Part"
    child.belongs_to :effectivity_down, -> { where("typesobject_id in (select id from typesobjects where name='EFF')") },	class_name: 'Part'
    child.belongs_to :variant_down, -> { where("typesobject_id in (select id from typesobjects where name='VAR')") },		class_name: 'Part'
  end

  # objects which could be father of a link:"document", "part", "project", "customer", "definition", "history", "link"(pour les effectivites)
  with_options foreign_key: 'father_id' do |father|
    father.belongs_to :document_up, class_name: 'Document'
    father.belongs_to :part_up, class_name: 'Part'
    father.belongs_to :project_up, class_name: 'Project'
    father.belongs_to :customer_up, class_name: 'Customer'
    father.belongs_to :definition_up, class_name: 'Definition'
    father.belongs_to :history_up, class_name: 'Ruote::Sylrplm::HistoryEntry'
    father.belongs_to :link_up, class_name: 'Link'
    father.belongs_to :variant_up, -> { where("ftypesobject_id in (select id from typesobjects where name='VAR')") }, class_name: 'Part'
  end

  # rails2 has_many :links_link_part,    :class_name => "Link",    :foreign_key => "father_id",    :conditions => { father_plmtype: 'link', child_plmtype: 'part' }
  has_many :links_link_part, class_name: 'Link', foreign_key: 'father_id'

  has_many :effectivities, through: :links_link_part, source: :effectivity_down

  # ##non validates_uniqueness_of :child_id, scope: [:child_plmtype, :father_id, :father_type]
  # ##validates :link_uniqueness, :validity
  # before_save :link_uniqueness, :validity
  before_save :validity

  def effectivities_old_voircidessus
    fname = "#{self.class.name}.#{__method__}"
    # LOG.info(fname) {"self=#{self}"}
    ret = []
    ::Link.find(:all,
                conditions: ["father_plmtype='link' and child_plmtype='part' and father_id = #{id}"]).each do |lnk|
      LOG.debug(fname) { "lnk=#{lnk.ident} child.type=#{lnk.child.typesobject.name}" }
      ret << lnk.child if lnk.child.typesobject.name == 'EFF'
    end
    ret
  end

  def initialize(*args)
    fname = "Link:#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "initialize args debut=#{args.length}:#{args.inspect}" }
    super
    unless args.empty?
      unless args[0].nil? || args[0][:father].nil? || args[0][:child].nil? || args[0][:relation].nil?
        # LOG.debug(fname) {"initialize self GO:father=#{args[0][:father]}"}
        self.father_plmtype = args[0][:father].modelname
        self.father_id = args[0][:father].id
        # LOG.debug(fname) {"initialize self GO:father=#{args[0][:child]}"}
        self.child_plmtype = args[0][:child].modelname
        self.child_id = args[0][:child].id
        # LOG.debug(fname) {"initialize self GO:father=#{args[0][:relation]} id=#{args[0][:relation].id}"}
        self.relation_id = args[0][:relation].id
        self.type_values = args[0][:relation].type_values
      end
    end
    LOG.debug(fname) { "initialize self fin=#{inspect}" }
  end

  ''

  # in fact, this is not useful to test uniqueness here, the cardinality permit to have several links identicals
  #
  def link_uniqueness_obsolete
    fname = "#{self.class.name}.#{__method__}"
    ret = true
    cond = ['father_plmtype = ? and child_plmtype = ? and father_id = ? and child_id = ? and relation_id = ? ',
            father_plmtype, child_plmtype, father_id, child_id, relation_id]
    unless ::Link.find(:first, conditions: cond).nil?
      errors.add(:base, 'Link already exists!')
      ret = false
    end
    LOG.debug(fname) { "link_uniqueness '#{self}' #{cond} = #{ret}" }
    ret
  end

  def designation
    ''
  end

  def before_save
    fname = "#{self.class.name}.#{__method__}"
    self.domain = father.domain if father.respond_to?(:domain)
    self.domain = child.domain if domain.nil? && child.respond_to?(:domain)
    LOG.debug(fname) { "before_save:self=#{self}" }
  end

  def user=(user)
    def_user(user)
  end

  def validity
    fname = "#{self.class.name}.#{__method__}"
    begin
      # LOG.info(fname) {"father.typesobject=#{father.typesobject} relation.father_typesobject=#{relation.father_typesobject}"}
      # LOG.info(fname) {"child.typesobject=#{child.typesobject} relation.child_typesobject=#{relation.child_typesobject}"}
      rel = relation
      msg = "relation:'#{rel.inspect}'"
      valid	= !rel.nil?
      if valid
        msg = "relation.father_plmtype:'#{rel.father_plmtype}' <> (father_plmtype:'#{father_plmtype}' and '#{PlmServices.get_property(:PLMTYPE_GENERIC)}')"
        valid = (rel.father_plmtype == father_plmtype || rel.father_plmtype == PlmServices.get_property(:PLMTYPE_GENERIC))
        if valid
          msg = "relation.child_plmtype:'#{relation.child_plmtype}' <> (child_plmtype:'#{child_plmtype}' and '#{PlmServices.get_property(:PLMTYPE_GENERIC)}')"
          valid = (child_plmtype == rel.child_plmtype || rel.child_plmtype == PlmServices.get_property(:PLMTYPE_GENERIC))
          if valid
            if father.respond_to? :typesobject
              msg = "relation.father_type:'#{relation.father_typesobject}' <> (father.type:'#{father.typesobject}' and '#{PlmServices.get_property(:TYPE_GENERIC)}')"
              valid = (father.typesobject.name == rel.father_typesobject.name || rel.father_typesobject.name == PlmServices.get_property(:TYPE_GENERIC))
            end
            if valid
              if child.respond_to? :typesobject
                msg = "relation.child_type:'#{relation.child_typesobject}' <> (child.type:'#{child.typesobject}' and '#{PlmServices.get_property(:TYPE_GENERIC)}')"
                valid = (child.typesobject.name == rel.child_typesobject.name || rel.child_typesobject.name == PlmServices.get_property(:TYPE_GENERIC))
              end
            end
          end
        end
      end
      errors.add(:base, "Link is not valid:<br/>#{msg}") unless valid
    rescue Exception => e
      valid = false
      msg = 'Exception during link validity test:'
      msg += "<br/>exception=#{e}"
      errors.add(:base, msg)
    end
    LOG.debug(fname) { "validity '#{self}' =#{valid} msg=#{msg}" }
    valid
  end

  def cardinality_count
    nb_used = self.class.nb_used(relation)
    unless nb_used >= relation.cardin_use_min && (relation.cardin_use_max == -1 || nb_used <= relation.cardin_use_max)
      errors.add(:base, 'Cardinality is not valid!')
    end
  end

  def father
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"father_plmtype=#{father_plmtype} father_id=#{father_id}"}
    get_object(father_plmtype, father_id) unless father_plmtype.blank? || father_id.blank?
  end

  def father_ident
    fname = "#{self.class.name}.#{__method__}"
    ret = ''
    if father.nil?
      msg = I18n.t(:database_not_consistency, msg: ' no child !')
      LOG.error("Error on:#{inspect}")
      LOG.error("Error:#{msg}")
      ret += ::Link::NO_FATHER
    else
      ret = "#{father_id}:#{father.modelname}"
      if father.respond_to? :typesobject
        ret += father.typesobject.to_s
      else
        msg = I18n.t(:database_not_consistency, msg: "#{father} has no type !")
        LOG.error("Error on:#{inspect}")
        LOG.error("Error:#{msg}")
        ret += ::Typesobject::NO_TYPE
      end
      ret += "=#{father.ident_plm}"
    end
  end

  def child
    get_object(child_plmtype, child_id) unless child_plmtype.blank? || child_id.blank?
  end

  def child_ident
    fname = "#{self.class.name}.#{__method__}"
    ret = ''
    if child.nil?
      msg = I18n.t(:database_not_consistency, msg: ' no child !')
      LOG.error("Error on:#{inspect}")
      LOG.error("Error:#{msg}")
      ret += ::Link::NO_CHILD
    else
      ret = "#{child_id}:#{child.modelname}"
      if child.respond_to? :typesobject
        ret += child.typesobject.to_s
      else
        msg = I18n.t(:database_not_consistency, msg: "#{child} has no type !")
        LOG.error("Error on:#{inspect}")
        LOG.error("Error:#{msg}")
        ret += ::Typesobject::NO_TYPE
      end
      ret += "=#{child.ident_plm}"
    end
  end

  def father=(afather)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "afather=#{afather}" }
    self.father_plmtype = afather.modelname
    self.father_id = afather.id
  end

  def child=(achild)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "achild=#{achild}" }
    self.child_plmtype = achild.modelname
    self.child_id = achild.id
  end

  def relation=(relation)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "relation.type=#{relation.typesobject}, fields=#{relation.typesobject.fields}" }
    # TODO: pour eviter super: no superclass method `relation=' for #<Link:0x9aceec4> super
    self.type_values = relation.typesobject.fields
    self.relation_id = relation.id
  end

  def user=(user)
    def_user(user)
  end

  def relation_ident
    rel = Relation.find(relation_id) unless relation_id.nil?
    relation_id.to_s + (rel.ident)
  rescue StandardError
    relation_id.to_s
  end

  #
  # return the identifier of the link
  #
  def ident
    "#{(father.nil? ? 'father null' : father.ident_plm)}-#{(relation.nil? ? 'relation null' : relation.ident)}-#{(child.nil? ? 'child null' : child.ident_plm)}-#{type_values}"
  end

  #
  # return the list of mdlid attribute of all effectivities
  #
  def effectivities_mdlid
    @effectivities_mdlid ||= effectivities.map(&:mdlid)
  end

  #
  # menage des effectivites non presentes dans effs_mdlid
  # argum effectivities_mdlids : list of effectivities to keep, ex [part.24, part.22]
  #
  def clean_effectivities(effectivities_mdlids)
    fname = "#{self.class.name}.#{__method__}"
    LOG.info(fname) { "effectivities_mdlids: #{effectivities_mdlids}" }
    links_link_part.each do |current_link_effectivity|
      # ###LOG.info(fname) { "current_link_effectivity=#{current_link_effectivity.ident} : #{current_link_effectivity.child.mdlid}" }
      unless effectivities_mdlids.include?(current_link_effectivity.child.mdlid)
        LOG.info(fname) { "destroy:#{current_link_effectivity.ident}" }
        current_link_effectivity.destroy
      end
    end
  end

  def after_find
    fname = "#{self.class.name}.#{__method__}"
    LOG.info(fname) { '--------------------------------------------------' }
    rel = relation
    unless rel.nil?
      if type_values.nil?
        fields = rel.typesobject.fields
        self.type_values = fields unless fields.nil?
        # LOG.info(fname) {"#{fields} : #{self.type_values}"}
      end
    end
  end

  def type
    'link'
  end

  def update_link(user, params_link)
    update_accessor(user)
    update_attributes(params_link)
  end

  # bidouille infame car l'association ne marche pas
  def relation
    fname = "#{self.class.name}.#{__method__}"
    # LOG.error(fname) {"relation:#{relation_id}"}
    # #PlmServices.stack("link relation",100)
    ret = nil
    begin
      ret = Relation.find(relation_id)
    rescue Exception => e
      LOG.error(fname) { "relation not found:#{e}" }
      ret = nil
    end
    # LOG.error(fname) {"relation:#{relation_id} : #{ret}"}
    ret
  end

  def relation_name
    fname = "#{self.class.name}.#{__method__}"
    LOG.error(fname) { '-----------------------------------------' }
    rel = relation
    (ret.nil? ? 'nil' : ret.name)
  end

  def self.valid?(_father, _child, _relation)
    raise Exception, "Don't use this method Link.valid?"
  end

  def self.find_childs(father, child_plmtype = nil, relation_name = nil)
    find_childs_with_father_plmtype(father.modelname, father, child_plmtype, relation_name)
  end

  def self.find_childs_with_father_plmtype(father_plmtype, father, child_plmtype = nil, relation_name = nil)
    fname = "#{self.class.name}.#{__method__}" + ':'
    if child_plmtype.nil?
      cond = "father_plmtype='#{father_plmtype}' and father_id =#{father.id}"
    else
      cond = "father_plmtype='#{father_plmtype}' and child_plmtype='#{child_plmtype}' and father_id =#{father.id}"
    end
    links = Link.all.where(cond).order('child_id DESC')
    if relation_name.nil?
      ret = links
    else
      ret = []
      links.each do |lnk|
        ret << lnk if lnk.relation.name == relation_name
      end
    end
    ret.to_a
  end

  def self.find_child(father_plmtype, father, child_plmtype, child)
    where("father_plmtype='#{father_plmtype}' and child_plmtype='#{child_plmtype}' and father_id =#{father.id} and child_id =#{child.id}").order('child_id').to_a
  end

  def self.find_fathers(child, father_plmtype = nil)
    if father_plmtype.nil?
      cond = "child_plmtype='#{child.modelname}' and child_id =#{child.id}"
    else
      cond = "child_plmtype='#{child.modelname}' and child_id =#{child.id} and father_plmtype='#{father_plmtype}'"
    end
    all.where(cond).order('child_id').to_a
  end

  def self.get_all_fathers(child)
    fname = "#{self.class.name}.#{__method__}" + ':'
    child_plmtype = child.modelname
    cond = "child_plmtype='#{child_plmtype}' and child_id =#{child.id}"
    ret = all.where(cond).order('child_id').to_a
    ret
  end

  def self.find_by_father_plmtype(plmtype)
    fname = "#{self.class.name}.#{__method__}" + ':'
    links = all.where("father_plmtype='#{plmtype}'").order('father_id DESC , child_id DESC').to_a
  end

  def self.is_child_of(father_plmtype, father, child_plmtype, child)
    ret = false
    # childs=find_childs(father_type, father, child_plmtype)
    nb = all.where("father_plmtype='#{father_plmtype}' and child_plmtype='#{child_plmtype}' and father_id =#{father} and child_id=#{child}").to_a.size
    ret = nb > 0
  end

  def self.nb_linked(child_plmtype, child)
    ret = 0
    links = all.where("child_plmtype='#{child_plmtype}' and child_id =#{child}").to_a
    ret = links.count unless links.nil?
    ret
  end

  def self.nb_occured(father, relation)
    fname = "#{self.class.name}.#{__method__}"
    ret = 0
    links = find(:all, include: :relation,
                       conditions: ['relations.father_plmtype = ? and relations.child_plmtype= ? and relations.child_typesobject_id = ? and father_id = ?',
                                    relation.father_plmtype, relation.child_plmtype, relation.child_typesobject_id, father.id])
    ret = links.count unless links.nil?
    ret
  end

  def self.nb_used(relation)
    fname = "#{self.class.name}.#{__method__}"
    ret = 0
    LOG.debug(fname) { "Link.nb_used:#{relation.child_plmtype}:#{relation.child_typesobject_id}" }
    links = find(:all, include: :relation, conditions: ['relations.child_plmtype = ? and relations.child_typesobject_id = ?', relation.child_plmtype, relation.child_typesobject_id])
    ret = links.count unless links.nil?
    ret
  end

  def self.get_conditions(_filter)
    nil
  end

  def self.linked?(obj)
    fname = "#{self.class.name}.#{__method__}"
    if obj.respond_to? :typesobject
      if obj.typesobject.nil?
        LOG.error(fname) { "DATABASE_CONSISTENCY_ERROR: no type for #{obj.ident_plm}" }
        false
      else
        relation_recent_action = ::Relation.find_by_name(::SYLRPLM::RELATION_RECENT_ACTION)
        cond = "child_plmtype = '#{obj.modelname}' and child_id = #{obj.id} and relation_id != #{relation_recent_action.id}"
        ret = Link.where(cond).count
        LOG.info "linked cond=#{cond} nb=#{ret}"
        ret>0
      end
    else
      false
    end
  end

  # == Role: this function duplicate the link
  # == Arguments
  # * +new_father+ the new_father become the father of the new link
  # * +user+ - The user which proceed the duplicate action
  # == Usage from controller or script:
  #    if @object_plm.save
  #		  lnk_orig = Link.find(lnkid)
   #			lnk_new = lnk_orig.duplicate(new_obj, user)
  # === Result
  # 	the duplicate object , all characteristics of the object are copied excepted the followings:
  # * +new_father+ become the father of the new link
  # * +responsible/group/projowner+ : the accessor is the user
  # == Impact on other components
  #
  def duplicate(new_father, user)
    fname = "#{self.class.name}.#{__method__}"
    LOG.info(fname) { "duplicate: new_father=#{new_father.inspect}" }
    # rails2 ret = self.clone
    ret = dup
    # ret.father_plmtype=new_father.modelname
    ret.father_id = new_father.id
    ret.def_user(user)
    # LOG.info(fname) {"new link=#{ret.inspect}"}
    ret
  end
end
