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
	def validate
		errors.add_to_base I18n.t("valid_relation_cardin_occur_max") if cardin_occur_max != -1 && cardin_occur_max < cardin_occur_min
		errors.add_to_base I18n.t("valid_relation_cardin_use_max") if cardin_use_max != -1 && cardin_use_max < cardin_use_min
	end

	def initialize(*args)
		super
		if args.empty?
			self.father_plmtype = Typesobject.get_objects_with_type.first
			self.child_plmtype  = Typesobject.get_objects_with_type.first
		self.set_default_values(true)
		end
	end

	def self.create_new(params)
		raise Exception.new "Don't use this method!"
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
		ret+=father_typesobject.name unless father_typesobject.nil?
		# on recommence plus simplement
		ret="#{typesobject.name}.#{name}" unless typesobject.nil?
		ret
	end

	def self.relations_for(father)
		fname="Relations.#{__method__}:#{father.model_name}:"
		ret={}
		## pas de ret[::SYLRPLM::PLMTYPE_GENERIC] = []
		Typesobject.get_objects_with_type.each do |t|
			ret[t] = []
		end
		cond="(father_plmtype = '#{father.model_name}' or father_plmtype = '#{::SYLRPLM::PLMTYPE_GENERIC}' )"
		##cond="(father_plmtype = '#{father.model_name}' )"
		## ko car show incomplet !!! cond+=" and (father_typesobject_id = '#{father.typesobject_id}')"
		find(:all, :order => "name",
      :conditions => [cond]).each do |rel|
			if rel.child_plmtype==::SYLRPLM::PLMTYPE_GENERIC
				# ok pour tous les types de fils
				Typesobject.get_objects_with_type.each do |t|
					ret[t] <<rel
				end
			else
			ret[rel.child_plmtype] << rel
			end
		end
		LOG.info (fname){"cond=#{cond}, #{ret.count} relations trouvees"}
		ret.each {|r| r.each {|rel| LOG.debug rel}}
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
		cond+=" (child_plmtype='#{child_plmtype}' or child_plmtype='#{::SYLRPLM::PLMTYPE_GENERIC}')"
		cond+=" and name='#{name}'"
		#puts "Relations."+__method__.to_s+":"+cond
		find(:first,
      :conditions => [ cond ])
	end

	def self.by_types(father_plmtype, child_plmtype, father_typesobject_id, child_typesobject_id)
		cond="father_plmtype='#{father_plmtype}' and child_plmtype='#{child_plmtype}' and father_typesobject_id='#{father_typesobject_id}' and child_typesobject_id='#{child_typesobject_id}' "
		#puts "Relations."+__method__.to_s+":"+cond
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
		LOG.debug (fname) {"types_father=#{ret[:types_father]}"}
		LOG.debug (fname) {"types_child=#{ret[:types_child]}"}
		LOG.debug (fname) {"types_plm=#{ret[:types_plm]}"}
		LOG.debug (fname) {"types=#{ret[:types].inspect}"}
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

end
