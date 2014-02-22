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
	#
	belongs_to :typesobject
	belongs_to :father_typesobject, class_name: "Typesobject"
	belongs_to :child_typesobject, class_name: "Typesobject"

	has_many :links
	has_and_belongs_to_many :views
	#
	RELATION_FROM_REVISION = "FROM_REVISION"
	RELATION_FROM_DUPLICATE = "FROM_DUPLICATE"
	def validate
		errors.add_to_base I18n.t("valid_relation_cardin_occur_max") if cardin_occur_max != -1 && cardin_occur_max < cardin_occur_min
		errors.add_to_base I18n.t("valid_relation_cardin_use_max") if cardin_use_max != -1 && cardin_use_max < cardin_use_min
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

	def types_father
		ret = Typesobject.get_types(father_plmtype)
		#puts "Relations."+__method__.to_s+":"+father_plmtype.to_s+":"+ret.inspect
		ret
	end

	def types_child
		ret = Typesobject.get_types(child_plmtype)
		#puts "Relations."+__method__.to_s+":"+child_plmtype.to_s+":"+ret.inspect
		ret
	end

	def ident
		aname="Relations."+__method__.to_s+":"
		sep_type  = ":"
		sep_child = "."
		sep_name  = " - "
		#puts aname+ "relation="+self.inspect
		ret=child_plmtype + sep_type
		ret+= child_typesobject.name unless child_typesobject.nil?
		ret+=sep_name + self.name unless self.name.nil?
		ret+=sep_name + father_plmtype + sep_type
		#puts aname+ "father_type="+father_type.inspect
		#ret+=father_typesobject.name unless father_typesobject.nil?

		# on recommence plus simplement
		ret="#{typesobject.name}.#{name}" unless typesobject.nil?
		ret
	end

	def self.relations_for(father, child_plmtype=nil, child_type=nil)
		fname="Relations.#{__method__}:father=#{father.model_name}:child_plmtype=#{child_plmtype}"
		LOG.debug(fname){"debut"}
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
		elsif !father.nil? && !child_plmtype.blank?
			father_plmtype = father.model_name
			father_type=father.typesobject
			type_any_any=Typesobject.find_by_forobject_and_name(PlmServices.get_property(:PLMTYPE_GENERIC), PlmServices.get_property(:TYPE_GENERIC))
			type_father_any=Typesobject.find_by_forobject_and_name(father_plmtype, PlmServices.get_property(:TYPE_GENERIC))
			type_father_father=father.typesobject
			type_any_father=Typesobject.find_by_forobject_and_name(PlmServices.get_property(:PLMTYPE_GENERIC), father_type.name)
			cond =  "("
			cond += "(father_plmtype = '#{type_any_any.forobject}' and (father_typesobject_id = #{type_any_any.id}))" unless type_any_any.nil?
			cond += " or (father_plmtype = '#{type_father_any.forobject}' and (father_typesobject_id = #{type_father_any.id}))" unless type_father_any.nil?
			cond += " or (father_plmtype = '#{type_father_father.forobject}' and (father_typesobject_id = #{type_father_father.id}))" unless type_father_father.nil?
			cond += " or (father_plmtype = '#{type_any_father.forobject}' and (father_typesobject_id = #{type_any_father.id}))" unless type_any_father.nil?
			cond += ")"
			cond += " and child_typesobject_id = '#{child_type.id}'" unless child_type.nil?
			#cond += " and (child_plmtype = '#{child_plmtype}' or child_plmtype = '#{PlmServices.get_property(:PLMTYPE_GENERIC)}')"
			cond += " and (child_plmtype = '#{child_plmtype}')"
		end
		ret = find(:all, :order => "name",
      :conditions => [cond],
      :group => "father_plmtype,id")
		LOG.debug(fname){"fin:cond=#{cond}, #{ret.size} relations trouvées pour #{father_plmtype}.#{father_type}=>#{child_plmtype}.#{child_type}"}
		#LOG.debug(fname){"fin:ret(#{ret.count})=#{ret}"}
		ret
	end

	

	def self.relations_for_old(father, child_plmtype=nil)
		fname="Relations.#{__method__}:father=#{father.model_name}:child_plmtype=#{child_plmtype}"
		LOG.debug(fname){"debut"}
		ret={}
		## pas de ret[::SYLRPLM::PLMTYPE_GENERIC] = []
		Typesobject.get_objects_with_type.each do |t|
			ret[t] = []
		end
		cond="(father_plmtype = '#{father.model_name}' or father_plmtype = '#{PlmServices.get_property(:PLMTYPE_GENERIC)}' )"
		##cond="(father_plmtype = '#{father.model_name}' )"
		## ko car show incomplet !!! cond+=" and (father_typesobject_id = '#{father.typesobject_id}')"
		find(:all, :order => "name",
      :conditions => [cond]).each do |rel|
		#LOG.debug(fname){"rel=#{rel} child_plmtype=#{child_plmtype}"}
			if rel.child_plmtype == PlmServices.get_property(:PLMTYPE_GENERIC)
				# generic => ok pour tous les types plm de fils
				Typesobject.get_objects_with_type.each do |t|
				#LOG.debug(fname){"#{t} : #{child_plmtype}"}
					if child_plmtype.nil? || child_plmtype.to_s==t.to_s
						# seulement pour ce type
						unless ret[t].include? rel
							LOG.debug(fname){"cas generique:#{rel}"}
						ret[t] << rel
						end
					end
				end
			else
				if child_plmtype.nil?
					LOG.debug(fname){"cas child_plmtype nil:#{rel}"}
					unless ret[rel.child_plmtype].include? rel
					ret[rel.child_plmtype] << rel
					end
				else
					if rel.child_plmtype.to_s == child_plmtype.to_s
						unless ret[rel.child_plmtype].include? rel
							LOG.debug(fname){"cas child_plmtype non nil:#{rel}"}
						ret[rel.child_plmtype] << rel
						end
					end
				end
			end
		end
		#LOG.info (fname){"cond=#{cond}, #{ret.count} relations trouvees"}
		#ret.each {|r| r.each {|rel| LOG.debug rel}}
		LOG.debug(fname){"fin"}
		ret
	end

	def self.names
		ret=Relation.connection.select_rows("SELECT DISTINCT name FROM #{Relation.table_name}").flatten.uniq
		###puts "Relations."+__method__.to_s+":"+ret.inspect
		ret
	end

	def self.by_values_and_name(father_plmtype, child_plmtype, father_type, child_type, name)
		###cond="(father_plmtype='#{father_plmtype}' or father_plmtype='#{::SYLRPLM::PLMTYPE_GENERIC}')"
		cond="(father_plmtype='#{father_plmtype}')"
		cond+=" and"
		cond+=" (child_plmtype='#{child_plmtype}' or child_plmtype='#{PlmServices.get_property(:PLMTYPE_GENERIC)}')"
		cond+=" and name='#{name}'"
		#puts "Relations."+__method__.to_s+":"+cond
		find(:first,
      :conditions => [ cond ])
	end

	def self.by_types(father_plmtype, child_plmtype, father_typesobject_id, child_typesobject_id)
		cond="father_plmtype='#{father_plmtype}' and child_plmtype='#{child_plmtype}' and father_typesobject_id='#{father_typesobject_id}' and child_typesobject_id='#{child_typesobject_id}' "
		puts "Relations."+__method__.to_s+":"+cond
		find(:first,
      :conditions => [ cond ])
	end

	def datas
		fname="Relations.#{__method__}:"
		ret={}
		ret[:types_father]= types_father
		ret[:types_child] = types_child
		ret[:types_plm]   = Typesobject.get_objects_with_type
		ret[:types]       = Typesobject.get_types(:relation)
		#LOG.debug (fname) {"types_father=#{ret[:types_father]}"}
		#LOG.debug (fname) {"types_child=#{ret[:types_child]}"}
		#LOG.debug (fname) {"types_plm=#{ret[:types_plm]}"}
		#LOG.debug (fname) {"types=#{ret[:types].inspect}"}
		ret
	end

	def self.datas_by_params(params)
		fname="Relations.#{__method__}:"
		ret={}
		ret[:types_father]=Typesobject.get_types(params["father_plmtype"]) unless params["father_plmtype"].nil?
		#LOG.info (fname) {"types_father for '#{params["father_plmtype"]}'=#{ret[:types_father]}"}
		ret[:types_child]=Typesobject.get_types(params["child_plmtype"]) unless params["child_plmtype"].nil?
		#LOG.info (fname) {"types_child for '#{params["child_plmtype"]}'=#{ret[:types_child]}"}
		ret
	end

	def stop_tree?
		PlmServices.get_property(:TREE_RELATION_STOP).include?(self.name)
	end
end
