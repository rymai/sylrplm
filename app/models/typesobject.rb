class Typesobject < ActiveRecord::Base
	include Models::SylrplmCommon
	validates_presence_of :forobject, :name

	has_many :datafiles
	has_many :documents
	has_many :parts
	has_many :projects
	has_many :customers

	named_scope :order_default, :order=>"name ASC"
	named_scope :find_all , order_default.all
	#
	def initialize(params=nil)
		super(params)
		fname="Typesobject.#{__method__}"
		LOG.debug (fname){"params=#{params}:\n#{params.nil?}:#{self.inspect}"}
		LOG.debug (fname){"#{self.inspect}"}
	end

	def self.get_all
		order_default.find_all
	end

	def self.get_types(s_object)
		fname="Typesobject.#{__method__}(#{s_object})"
		ret=find_all_by_forobject(s_object.to_s, :order => :name)
		unless ret.is_a?(Array)
			ret = [ret]
		end
		LOG.debug (fname){"types=#{ret}"}
		ret
	end

	def self.get_types_names(s_object)
		ret=[]
		types=get_types(s_object)
		types.each do |t|
			ret<<t.name
		end
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
		#   +objets generiques: ::SYLRPLM::PLMTYPE_GENERIC
		# objets non pris en compte:
		#   ar_workitem: pas de besoin
		#   definition: pas de besoin
		ret=[::SYLRPLM::PLMTYPE_GENERIC, "document", "part", "project", "customer", "forum", "datafile", "relation", "link", "history_entry", "relation", "user"].sort
		ret
	end

	def self.find_for(object)
		#find(:all, :order=>"object,name", :conditions => ["object = '#{object}' "])
		order_default.find_all_by_forobject(object)
	end

	def self.get_conditions(filter)
		filter = filters.gsub("*","%")
		ret={}
		unless filter.nil?
			ret[:qry] = "object LIKE :v_filter or name LIKE :v_filter or description LIKE :v_filter "
			ret[:values]={:v_filter => filter}
		end
		ret
	#conditions = ["object LIKE ? or name LIKE ? or description LIKE ? ",
	end

	def ident
		"#{forobject}.#{name}"
	end
end
