class Typesobject < ActiveRecord::Base
	include Models::SylrplmCommon
	validates_presence_of :forobject, :name
	validates_uniqueness_of :name, :scope => :forobject

	has_many :datafiles
	has_many :documents
	has_many :parts
	has_many :projects
	has_many :customers
	has_many :statusobject

	named_scope :order_default, :order=>"forobject ASC, name ASC"
	named_scope :find_all , order_default.all
	#
	def initialize(params=nil)
		super(params)
		fname="Typesobject.#{__method__}"
	#LOG.debug (fname){"params=#{params}:\n#{params.nil?}:#{self.inspect}"}
	#LOG.debug (fname){"#{self.inspect}"}
	end

	def self.get_all
		order_default.find_all
	end

	def name_translate
		fname="Typesobject.#{__method__}"
		ret=PlmServices.translate("typesobject_name_#{name}")
		#LOG.debug (fname){"name=#{name} tr=#{ret}"}
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
		#LOG.info (fname) {"MODELS_OBSERVE=#{::Plmobserver::MODELS_OBSERVE}"}
		order_default.find_all.each do |type|
		#LOG.info (fname) {"type.name=#{type.forobject}"}
			ret << type if ::Plmobserver::MODELS_OBSERVE.include? type.forobject
		end
		ret
	end

	def self.get_types(s_object, with_generic=false)
		fname="Typesobject.#{__method__}(#{s_object})"
		sgeneric = PlmServices.get_property(:TYPE_GENERIC)
		stypes = order_default.find_all_by_forobject(s_object.to_s)
		ret= []
		stypes.each do |type|
		#LOG.debug (fname) {"type:#{type}"}
			if type.name != sgeneric || with_generic
			###############TODO not here !!! someone need he reel name type.name = type.name_translate
			ret << type
			end
		end
		unless ret.is_a?(Array)
			ret = [ret]
		end
		#LOG.debug (fname) {"types=#{ret}"}
		ret
	end

	def self.get_types_names_obsolete(s_object)
		ret=[]
		types=get_types(s_object)
		types.each do |t|
			ret<<t.name
		end
		ret
	end

	def self.get_default(obj)
		fname="Typesobject.#{__method__}:"
		ret=find_by_forobject(obj.model_name)
		#LOG.debug (fname){"ret=#{ret}"}
		ret
	end

	# liste des objets pouvant entrer dans une relation
	# ils doivent avoir les caracteristiques suivantes:
	# => association avec l'objet Typesobject. belongs_to :typesobject
	#      ou methode typesobject
	# => methode model_name utilisee par l'objet Link entre autre
	# => methode ident utilisee par l'objet Link
	# => exemple pour history_entry dont le schema est externe (module openwfe)
	# def typesobject
	#   Typesobject.find_by_object(model_name)
	# end
	# def model_name
	#   "history_entry"
	# end
	# def ident
	#   fei+"_"+wfid+"_"+expid+"_"+wfname
	# end
	def self.get_objects_with_type
		# liste complete potentielle:
		#   objets du schema: "document", "part", "project", "customer", "forum", "definition", "datafile", "relation", "user", "link" (pour la conf)
		#   +objets ayant les methodes adequates: "ar_workitem", "history_entry"
		#   +objets generiques: ::SYLRPLM::PROPERTIES, PLMTYPE_GENERIC
		# objets non pris en compte:
		#   ar_workitem: pas de besoin
		#   definition: pas de besoin
		ret=[::SYLRPLM::PLM_PROPERTIES, PlmServices.get_property(:PLMTYPE_GENERIC), "document", "part", "project", "customer", "forum", "datafile", "relation", "link", "history_entry", "relation", "user"].sort
		ret
	end

	def self.find_for(s_object)
		fname="Typesobject.#{__method__}(#{s_object})"
		LOG.info (fname) { "%TODO_OBSOLETE%"}
		get_types(s_object)
	end

	def self.generic(s_object)
		Typesobject.find_by_forobject_and_name(s_object, PlmServices.get_property(:TYPE_GENERIC))
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
		ret=nil
		values = get_fields_values()
		#LOG.debug (fname) {"values=#{values}"}
		unless values.nil?
			values.delete("_type_only_")
			#LOG.debug (fname) {"values after remove=#{values}"}
			ret = ActiveSupport::JSON.encode(values)
		end
		#LOG.debug (fname) {"fields=#{ret}"}
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
		 get_fields_values_type_only[key]
	end

	def get_fields_values_type_only
		get_fields_values_("_type_only_")
	end

	def get_fields_values_(key=nil)
		fname="Typesobject.#{__method__}:#{name}"
		ret=nil
		if self.respond_to? :fields
			unless fields.blank?
				#LOG.debug (fname) {"key=#{key} fields=#{fields}"}
				begin
					decod = ActiveSupport::JSON.decode(fields)
					#LOG.debug (fname) {"key=#{key} decod=#{decod}"}
=begin
					ret={}
					begin
						decod.each do |decod_part|
							ret[decod_part[0]] = eval(decod_part[1])
							LOG.debug (fname) {"eval(#{decod_part[1]}=#{ret[decod_part[0]]}"}
						end
					rescue Exception=>e
					LOG.error (fname) {"key=#{key} Decod is not a ruby bloc : #{decod} : #{e}"}
					ret=decod
					end
=end
ret=decod
				rescue Exception => e
					LOG.error (fname) {"key=#{key} Error during field decoding from JSON : fields=#{fields}"}
					LOG.error (fname) {"key=#{key} Error during field decoding from JSON : Exception=#{e}"}
					ret=nil
				end
			end
		end
		#LOG.debug (fname) {"key=#{key} ret=#{ret}"}
		unless ret.nil?
			unless key.nil?
			ret=ret[key]
			end
		end
		#LOG.debug (fname) {"key=#{key} ret=#{ret}"}
		ret
	end

end
