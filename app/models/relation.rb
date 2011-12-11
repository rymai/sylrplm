class Relation < ActiveRecord::Base
  include Models::SylrplmCommon
  #validates_presence_of :type, :name, cardin_occur_min, cardin_occur_max, cardin_use_min, cardin_use_max
  validates_presence_of :type, :name
  #validates_uniqueness_of :name
  validates_numericality_of :cardin_occur_min,  { :only_integer => true, :greater_than_or_equal_to => 0}
  validates_numericality_of :cardin_use_min, { :only_integer => true, :greater_than_or_equal_to => 0 }
  #
  attr_accessor :link_attributes
  #
  RELATION_NICK={:datafile=>"F", :document => "D", :part => "A", :project =>"P", :customer => "C", :user => "U"}
  belongs_to :type,
  :class_name => "Typesobject"
  belongs_to :father_type,
  :class_name => "Typesobject"
  belongs_to :child_type,
  :class_name => "Typesobject"

  #
  def validate
    errors.add_to_base I18n.t("valid_relation_cardin_occur_max") if cardin_occur_max != -1 && cardin_occur_max < cardin_occur_min
    errors.add_to_base I18n.t("valid_relation_cardin_use_max") if cardin_use_max != -1 && cardin_use_max < cardin_use_min
  end
  def link_attributes=(att)
    @link_attributes = att
  end
  def link_attributes
    @link_attributes
  end
  def self.create_new(params)
    if(params!=nil)
      obj=Relation.new(params)
    else
      obj=Relation.new
      obj.set_default_values( true)
      obj.father_plmtype=Typesobject.get_objects_with_type.first
      obj.child_plmtype=Typesobject.get_objects_with_type.first
    end
    puts __FILE__+"."+__method__.to_s+":"+obj.inspect
    obj
  end

  def types_father
    ret = Typesobject.get_types(father_plmtype)
    #puts __FILE__+"."+__method__.to_s+":"+father_plmtype.to_s+":"+ret.inspect
    ret
  end

  def types_child
    ret = Typesobject.get_types(child_plmtype)
    #puts __FILE__+"."+__method__.to_s+":"+child_plmtype.to_s+":"+ret.inspect
    ret
  end

  def ident
    sep_type  = ":"
    sep_child = "."
    sep_name  = " - "
    child_plmtype+ sep_type+ child_type.name+ sep_name+ name+ sep_name+ father_plmtype+ sep_type+ father_type.name
  end

  def self.relations_for_type(type_object)
    ret={}
    Typesobject.get_objects_with_type.each do |t|
      ret[t] = []
    end
    find(:all, :order => "name",
      :conditions => ["father_plmtype = '"+type_object.to_s+"'"]).each do |rel|
      ret[rel.child_plmtype] << rel
    end
    #puts __FILE__+"."+__method__.to_s+":"+ret.inspect
    ret
  end

  def self.relations_for(object)
    Relation.relations_for_type(object.model_name)
  end

  def self.datas_by_params(params)
    ret={}
    ret["types_father"]=Typesobject.get_types(params["father_plmtype"])unless params["father_plmtype"].nil?
    ret["types_child"]=Typesobject.get_types(params["child_plmtype"])unless params["child_plmtype"].nil?
    ret
  end

  def self.names
    ret=Relation.connection.select_rows("SELECT DISTINCT name FROM #{Relation.table_name}").flatten.uniq
    puts __FILE__+"."+__method__.to_s+":"+ret.inspect
    ret
  end

  def self.by_values(father_plmtype, child_plmtype, father_type, child_type, name)
    cond="father_plmtype='#{father_plmtype}' and child_plmtype='#{child_plmtype}' and name='#{name}'"
    puts __FILE__+"."+__method__.to_s+":"+cond
    find(:first,
      :conditions => [ cond ])
  end

  def datas
    ret={}
    ret["types_father"]=types_father
    ret["types_child"]=types_child
    ret
  end
  
end
