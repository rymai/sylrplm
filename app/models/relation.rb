#encoding: utf-8
class Relation < ActiveRecord::Base
	include Models::SylrplmCommon
	#validates_presence_of :type, :name, cardin_occur_min, cardin_occur_max, cardin_use_min, cardin_use_max
	validates_presence_of :typesobject, :name
	validates_uniqueness_of :name
	validates_numericality_of :cardin_occur_min,  { :only_integer => true, :greater_than_or_equal_to => 0}
	validates_numericality_of :cardin_use_min, { :only_integer => true, :greater_than_or_equal_to => 0 }
	#
	attr_accessor :link_attributes
	attr_accessible :id, :name, :typesobject_id, :father_plmtype, :child_plmtype, :father_typesobject_id, :child_typesobject_id
	attr_accessible :paste_way, :cardin_occur_min, :cardin_occur_max,  :cardin_use_min, :cardin_use_max, :domain , :type_values

	#
	belongs_to :typesobject
	belongs_to :father_typesobject, class_name: "Typesobject"
	belongs_to :child_typesobject, class_name: "Typesobject"

	has_many :links
	has_and_belongs_to_many :views, :join_table=>:relations_views
	#
	RELATION_FROM_REVISION = "FROM_REVISION"
	RELATION_FROM_DUPLICATE = "FROM_DUPLICATE"
	#
	RELATION_PASTE_WAY_ALL = "all"
	RELATION_PASTE_WAY_MANUAL = "manual"
	RELATION_PASTE_WAY_INTERNAL = "internal"
	def validate
		self.errors.add :base, I18n.t("valid_relation_cardin_occur_max") if !cardin_occur_max.nil? && cardin_occur_max != -1 && cardin_occur_max < cardin_occur_min
		self.errors.add :base, I18n.t("valid_relation_cardin_use_max") if !cardin_use_max.nil? && cardin_use_max != -1 && cardin_use_max < cardin_use_min
	end

	def initialize(*args)
		super
		if args.empty?
			self.father_plmtype = Typesobject.get_objects_with_type.first
			self.child_plmtype  = Typesobject.get_objects_with_type.first
		#unless args[0][:user].nil?
		self.set_default_values_with_next_seq
		#end
		end
	end

	def name_translate
		PlmServices.translate("relation_#{name}")
	end

	def father_plmtype_translate
		PlmServices.translate("forobject_#{father_plmtype}")
	end

	def child_plmtype_translate
		PlmServices.translate("forobject_#{child_plmtype}")
	end

	def types_father
		fname="Relation.#{__method__}:"
		ret = ::Typesobject.get_types(father_plmtype, true)
		LOG.debug(fname) {":#{father_plmtype} :  #{ret.inspect}"}
		ret
	end

	def types_child
		fname="Relation.#{__method__}:"
		ret = ::Typesobject.get_types(child_plmtype, true)
		LOG.debug(fname) {":#{child_plmtype} :  #{ret.inspect}"}
		ret
	end

	def ident
		aname="Relations."+__method__.to_s+":"
		sep_type  = ":"
		sep_child = "."
		sep_name  = " - "
		sep="."
		#puts aname+ "relation="+self.inspect
		ret=child_plmtype + sep_type
		ret+= child_typesobject.name unless child_typesobject.nil?
		ret+=sep_name + self.name unless self.name.nil?
		ret+=sep_name + father_plmtype + sep_type
		#puts aname+ "father_type="+father_type.inspect
		#ret+=father_typesobject.name unless father_typesobject.nil?

		# on recommence plus simplement
		ret=""
		ret += "#{typesobject.name}.#{name}" unless typesobject.nil?
	# ret+= sep+father_typesobject.name unless father_typesobject.nil?
	# ret+= sep+child_typesobject.name unless child_typesobject.nil?
	end

	def self.get_paste_way
		[RELATION_PASTE_WAY_INTERNAL, RELATION_PASTE_WAY_MANUAL, RELATION_PASTE_WAY_ALL]
	end

	#
	# argum father: objet pere des relations a prendre en compte
	# argum child_plmtype: plmtype du fils a prendre en compte si non nul
	# argum child_type : objet fils a prendre en compte si non nul
	# argum relation_type_name : nom du type de la relation a prendre en compte si non nul
	#
	def self.relations_for(father, child_plmtype=nil, child_type=nil, relation_type_name=nil, relation_paste_way=nil)
		fname="Relations.#{__method__}"
		LOG.debug(fname) {"father=#{father} child_plmtype=#{child_plmtype} child_type=#{child_type} relation_type_name=#{relation_type_name} relation_paste_way=#{relation_paste_way}"}
		child_plmtype=child_plmtype.to_s
		child_type=child_type.to_s unless child_type.nil?
		relation_type_name=relation_type_name.to_s
		if father.nil? && child_plmtype.blank? && child_type.blank?
			# all is null, we return all relations
			father_plmtype = nil
			father_type = nil
			cond = nil
		elsif father.nil? && !child_plmtype.blank?
			# all with child=child
			father_plmtype = nil
			father_type = nil
			cond = "child_plmtype = '#{child_plmtype}'"
			cond += " and child_typesobject_id = '#{child_type.id}'" unless child_type.nil?
		#elsif !father.nil? && !child_plmtype.blank?
		elsif !father.nil?
			father_plmtype = father.modelname

			type_any_any=Typesobject.find_by_forobject_and_name(PlmServices.get_property(:PLMTYPE_GENERIC), PlmServices.get_property(:TYPE_GENERIC))
			type_father_any=Typesobject.find_by_forobject_and_name(father_plmtype, PlmServices.get_property(:TYPE_GENERIC))
			type_father_father=father.typesobject
			cond =  "("
			cond += "(father_plmtype = '#{type_any_any.forobject}' and (father_typesobject_id = #{type_any_any.id}))" unless type_any_any.nil?
			cond += " or (father_plmtype = '#{type_father_any.forobject}' and (father_typesobject_id = #{type_father_any.id}))" unless type_father_any.nil?
			cond += " or (father_plmtype = '#{type_father_father.forobject}' and (father_typesobject_id = #{type_father_father.id}))" unless type_father_father.nil?

			father_type=father.typesobject
			unless father_type.nil?
				type_any_father=Typesobject.find_by_forobject_and_name(PlmServices.get_property(:PLMTYPE_GENERIC), father_type.name)
				cond += " or (father_plmtype = '#{type_any_father.forobject}' and (father_typesobject_id = #{type_any_father.id}))" unless type_any_father.nil?
			end
			cond += ")"
			cond += " and child_typesobject_id = '#{child_type.id}'" unless child_type.nil?
			cond_plm_type=" and (child_plmtype = '#{child_plmtype}' or child_plmtype = '#{PlmServices.get_property(:PLMTYPE_GENERIC)}')"
		cond+=cond_plm_type unless child_plmtype.blank?
		#cond += " and (child_plmtype = '#{child_plmtype}')"
		end
		LOG.debug(fname) {"cond=#{cond}"}
		ret = all.where(cond).order("name").group("father_plmtype,id").to_a
		LOG.debug(fname){"ret=#{ret.count}"}
		ret.each do |rel|
			LOG.debug(fname){"rel.typesobject.name=#{rel.typesobject.name} rel.paste_way=#{rel.paste_way}"}
		end
		unless ret.nil?
			unless relation_type_name.blank?
				ret1=[]
				ret.each do |rel|
					LOG.debug(fname){"rel.name=#{rel.name} rel.typesobject.name=#{rel.typesobject.name}"}
					if rel.typesobject.name == relation_type_name
					ret1 << rel
					end
				end
			ret=ret1
			end
			unless relation_paste_way.blank?
				ret1=[]
				ret.each do |rel|
					LOG.info(fname){"rel.name=#{rel.name} rel.paste_way=#{rel.paste_way}"}
					if rel.paste_way == relation_paste_way
					ret1 << rel
					end
				end
			ret=ret1
			end
		end
		LOG.debug(fname){"fin:cond=#{cond} : #{ret.size} relations trouvées pour #{father_plmtype}.#{father_type}=>#{child_plmtype}.#{child_type}"}
		#LOG.debug(fname){"fin:ret(#{ret.count})=#{ret}"}
		ret
	end

	def self.names
		ret=Relation.connection.select_rows("SELECT DISTINCT name FROM #{Relation.table_name}").flatten.uniq
		###puts "Relations."+__method__.to_s+":"+ret.inspect
		ret
	end

	def self.by_values_and_name(father_plmtype, child_plmtype, father_type, child_type, name)
		fname="Relations.#{__method__}:"
		cond="(father_plmtype='#{father_plmtype}')"
		cond+=" and"
		cond+=" (child_plmtype='#{child_plmtype}' or child_plmtype='#{PlmServices.get_property(:PLMTYPE_GENERIC)}')"
		cond+=" and name='#{name}'"
		ret=where(cond).first
		LOG.debug(fname) {"cond=#{cond} ret=#{ret.inspect}"}
		ret
	end

	def self.by_types(father_plmtype, child_plmtype, father_typesobject_id, child_typesobject_id)
		fname="Relations.#{__method__}:"
		generic_type=Typesobject.find_by_name(PlmServices.get_property(:TYPE_GENERIC))
		cond="father_plmtype='#{father_plmtype}' and child_plmtype='#{child_plmtype}'";
		cond+=" and (father_typesobject_id='#{father_typesobject_id}' or father_typesobject_id='#{generic_type.id}')";
		cond+=" and (child_typesobject_id='#{child_typesobject_id}' or child_typesobject_id='#{generic_type.id}')"
		#rails2 find(:first,   :conditions => [ cond ])
		ret=where(cond).first
		LOG.debug(fname) {"Relation.by_types:cond=#{cond} ret=#{ret.inspect}"}
		ret
	end

	def datas
		fname="Relations.#{__method__}:"
		ret={}
		ret[:types_father]= types_father
		ret[:types_child] = types_child
		ret[:types_plm]   = Typesobject.get_objects_with_type
		ret[:types]       = Typesobject.get_types(:relation)
		#LOG.debug(fname) {"types_father=#{ret[:types_father]}"}
		#LOG.debug(fname) {"types_child=#{ret[:types_child]}"}
		#LOG.debug(fname) {"types_plm=#{ret[:types_plm]}"}
		#LOG.debug(fname) {"types=#{ret[:types].inspect}"}
		ret
	end

	def self.datas_by_params(params)
		fname="Relations.#{__method__}:"
		ret={}
		ret[:types_father]=Typesobject.get_types(params["father_plmtype"]) unless params["father_plmtype"].nil?
		#LOG.info(fname) {"types_father for '#{params["father_plmtype"]}'=#{ret[:types_father]}"}
		ret[:types_child]=Typesobject.get_types(params["child_plmtype"]) unless params["child_plmtype"].nil?
		#LOG.info(fname) {"types_child for '#{params["child_plmtype"]}'=#{ret[:types_child]}"}
		ret
	end

	def stop_tree?
		PlmServices.get_property(:TREE_RELATION_STOP).include?(self.name)
	end
end
