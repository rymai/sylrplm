class Typesobject < ActiveRecord::Base
	include Models::SylrplmCommon

attr_accessible :id, :forobject, :name, :rank, :fields, :description, :domain , :father_id

	validates_presence_of :forobject, :name
	validates_uniqueness_of :name, :scope => :forobject

	has_many :datafiles
	has_many :documents
	has_many :parts
	has_many :projects
	has_many :customers
	#bug! has_many :statusobject

	belongs_to :father, :class_name => "Typesobject"

	#rails4 named_scope :order_default, :order=>"forobject ASC, rank ASC, name ASC"
	#rails4 named_scope :find_all , order_default.all
	ORDER_DEFAULT="forobject ASC, rank ASC, name ASC"
	ORDER_DESC="forobject DESC, rank DESC, name DESC"
	#
	MODELS_PLM=["customer", "document", "part", "project"]
	NO_TYPE="-NO_TYPE-"

	#
	def initialize(params=nil)
		super(params)
		fname="Typesobject.#{__method__}"
	#LOG.debug(fname){"params=#{params}:\n#{params.nil?}:#{self.inspect}"}
	#LOG.debug(fname){"#{self.inspect}"}
	end

	def self.get_all
		order_default.all
	end

	def father_name
		(father ? father.name : "")
	end

	def others
		fname="Typesobject.#{__method__}"
		#rails2 res = ::Typesobject.find_all_by_forobject(self.forobject)
		res = ::Typesobject.all.where("forobject='#{self.forobject}'").to_a
		LOG.debug(fname) {"Typesobject:self=#{self.inspect} others=#{res.inspect}"}
		#
		if res.is_a?(Array)
		ret=res
		else
		ret=[]
		ret<<res
		end
		ret
	end

	def name_translate
		fname="Typesobject.#{__method__}"
		ret=PlmServices.translate("typesobject_name_#{name}")
		#LOG.debug(fname){"name=#{name} tr=#{ret}"}
		ret
	end

	def forobject_translate
		PlmServices.translate("forobject_#{forobject}")
	end

	#
	# return types for models observed by Plmobserver
	#
	def self.get_from_observer
		fname="Typesobject.#{__method__}"
		ret=[]
		#LOG.info(fname) {"MODELS_OBSERVE=#{::Plmobserver::MODELS_OBSERVE}"}
		all.order("forobject ASC, rank ASC, name ASC").to_a.each do |type|
		#LOG.info(fname) {"type.name=#{type.forobject}"}
			ret << type if ::Plmobserver::MODELS_OBSERVE.include? type.forobject
		end
		ret
	end

	def self.get_types(s_object, with_generic=false)
		fname="Typesobject.#{__method__}(#{s_object})"
		sgeneric = PlmServices.get_property(:TYPE_GENERIC)
		#stypes = where(forobject: s_object).order("forobject ASC, rank ASC, name ASC")
		#LOG.debug(fname) {"stypes:#{stypes}==========="}
		#if stypes.is_a?(Array)
		#a_types=stypes
		#else
		#a_types=[]
		#	a_types<<stypes
		#end
		ret= []
		#ou all.to_a.each (all renvoie une relation)
		#@news = Article.where(text: "example").order(:created_at).limit(4)
		Typesobject.all.order(:name).to_a.each  do |type|
		LOG.debug(fname) {"Typesobject type:#{type} #{type.forobject} ==? #{s_object} "}
			if(type.forobject.to_s == s_object.to_s)
				#a_types.each do |type|
				#LOG.debug(fname) {"type ok:#{type}"}
				if type.name != sgeneric || with_generic
				###############TODO not here !!! someone need he reel name type.name = type.name_translate
				ret << type
				end
			end
		end
		unless ret.is_a?(Array)
			ret = [ret]
		end
		LOG.debug(fname) {"s_object=#{s_object} types=#{ret.inspect}"}
		ret
	end

	def self.get_default(obj)
		fname="Typesobject.#{__method__}:"
		ret=find_by_forobject(obj.modelname)
		#LOG.debug(fname){"ret=#{ret}"}
		ret
	end

	# liste des objets pouvant entrer dans une relation
	# ils doivent avoir les caracteristiques suivantes:
	# => association avec l'objet Typesobject. belongs_to :typesobject
	#      ou methode typesobject
	# => methode modelname utilisee par l'objet Link entre autre
	# => methode ident utilisee par l'objet Link
	# => exemple pour history_entry dont le schema est externe (module openwfe)
	# def typesobject
	#   Typesobject.find_by_object(modelname)
	# end
	# def modelname
	#   "history_entry"
	# end
	# def ident
	#   fei+"_"+wfid+"_"+expid+"_"+wf_name
	# end
	def self.get_objects_with_type
		# liste complete potentielle:
		#   objets du schema: "document", "part", "project", "customer", "forum", "definition", "datafile", "relation", "user", "link" (pour la conf)
		#   +objets ayant les methodes adequates: "ar_workitem", "history_entry"
		#   +objets generiques: ::SYLRPLM::PROPERTIES, PLMTYPE_GENERIC
		# objets non pris en compte:
		#   definition: pas de besoin
		ret=[::SYLRPLM::PLM_PROPERTIES, PlmServices.get_property(:PLMTYPE_GENERIC), "ar_workitem", "document", "part", "project", "customer", "forum", "datafile", "relation", "link", "history_entry", "relation", "user"].sort
		ret
	end

	def self.find_for(s_object)
		fname="Typesobject.#{__method__}(#{s_object})"
		LOG.info(fname) { "%TODO_OBSOLETE%"}
		get_types(s_object)
	end

	def self.generic(s_object)
		fname="Typesobject.#{__method__}(#{s_object})"
		##Typesobject.find_by_forobject_and_name(s_object, PlmServices.get_property(:TYPE_GENERIC))
		generic_name=PlmServices.get_property(:TYPE_GENERIC)
		cond = " forobject = '#{s_object}' and name='#{generic_name}'"
		#rails2 ret=order_default.find(:all, :conditions => [cond])[0]
		ret=where(cond).order("forobject ASC, rank ASC, name ASC")[0]
		ret
	end

	def self.get_conditions(filter)
		filter = filter.gsub("*","%")
		ret={}
		unless filter.nil?
			ret[:qry] = "forobject LIKE :v_filter or name LIKE :v_filter or description LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
			ret[:values]={:v_filter => filter}
		end
		ret
	#conditions = ["object LIKE ? or name LIKE ? or description LIKE ? ",
	end

	def ident
		"#{forobject}.#{name}"
	end

	#return filds for copying in an object
	#we take all fields except _type_only_
	def get_fields
		fname="Typesobject.#{__method__}:#{name}"
		LOG.debug(fname) {">>>>"}
		ret=nil
		values = get_fields_values()
		LOG.debug(fname) {"avant remove type=#{values}"}
		newvalues={}
		unless values.nil?
			##modif de codage des valeurs values.delete("_type_only_")
			values.each do |key,value|
				unless key[0,"_type_only_".length]=="_type_only_"
					newvalues[key]=value[::Models::SylrplmCommon::TYPE_VALUES_VALUE]
					newvalues[key]="" if newvalues[key].blank?
				end
			end
			LOG.debug(fname) {"apres remove type=#{newvalues}"}
			ret = ActiveSupport::JSON.encode(newvalues)
		end
		LOG.debug(fname) {"<<<<fields=#{ret}"}
		ret
	end

	# renvoie l'objet contenu dans l'attribut fields
	# it is a hash

	def get_fields_values
		get_fields_values_(nil)
	end

	def get_fields_values_by_key(key)
		get_fields_values_(key)
	end

	def get_fields_values_type_only_by_key(key)
		fname="Typesobject.#{__method__}:#{name}"
		LOG.debug(fname) {"key=#{key}  self=#{self}"}
		fields_values = get_fields_values_type_only
		fields_values["_type_only_#{key}"] unless fields_values.nil?
	end

	def get_fields_values_type_only
		fname="Typesobject.#{__method__}:#{name}"
		ret=get_fields_values_
		LOG.debug(fname) {"fields_values=#{ret}"}
		unless ret.nil?
			ret.each do |key,value|
				if key.start_with?("_type_only_")
				ret.delete(key)
				end
			end
		end
	end

	def get_fields_values_(key=nil)
		fname="Typesobject.#{__method__}:#{name}"
		LOG.debug(fname) {">>>>key=#{key} self=#{self}"}
		ret=nil
		if self.respond_to? :fields
			unless fields.blank?
				LOG.debug(fname) {"key='#{key}' fields=#{fields}"}
				ret = self.decod_json(fields, key, self.name)
			end
		end
		#LOG.debug(fname) {"key=#{key} ret=#{ret}"}
		unless ret.nil?
			unless key.nil?
			ret=ret[key]
			end
		end
		LOG.debug(fname) {"key=#{key} ret=#{ret}"}
		ret
	end

end
