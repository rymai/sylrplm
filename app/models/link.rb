class Link < ActiveRecord::Base
	include Models::PlmObject
	include Models::SylrplmCommon
	# une seule occurence d'un fils de type donne dans un pere de type donne
	### verif par soft dans create_new validates_uniqueness_of :child_id, :scope => [:child_plmtype, :father_id, :father_type ]
	#validates_presence_of :name

	attr_accessor :user

	belongs_to :relation,
    :class_name => "Relation",
    :foreign_key => "relation_id"

	belongs_to :owner,
    :class_name => "User"

	belongs_to :group

	belongs_to :projowner,
    :class_name => "Project"

	NO_CHILD="-NO_CHILD-"
	NO_FATHER="-NO_FATHER-"
	#delegate :typesobject_id, :typesobject, to: :relation

	#objects which could be child of link: "document", "part", "project", "customer", "forum", "datafile"

	with_options :foreign_key => 'child_id' do |child|
		child.belongs_to :document_down ,
		:conditions => ["child_plmtype = 'document'"],
		:class_name => "Document"
		child.belongs_to :part_down ,
		:conditions => ["child_plmtype = 'part'"],
		:class_name => "Part"
		child.belongs_to :project_down ,
		:conditions => ["child_plmtype='project'"],
		:class_name => "Project"
		child.belongs_to :customer_down ,
		:conditions => ["child_plmtype='customer'"],
		:class_name => "Customer"
		child.belongs_to :forum_down ,
		:conditions => ["child_plmtype='forum'"],
		:class_name => "Forum"
		child.belongs_to :datafile_down ,
		:conditions => ["child_plmtype='datafile'"],
		:class_name => "Datafile"
		child.belongs_to :effectivity_down ,
		:conditions => ["child_plmtype = 'part' and parts.typesobject_id in (select id from typesobjects where name='EFF')"],
		:class_name => "Part"
		child.belongs_to :variant_down ,
		:conditions => ["child_plmtype = 'part' and parts.typesobject_id in (select id from typesobjects where name='VAR')"],
		:class_name => "Part"
	end

	#objects which could be father of a link:"document", "part", "project", "customer", "definition", "history", "link"(pour les effectivites)
	with_options :foreign_key => 'father_id' do |father|
		father.belongs_to :document_up , :conditions => ["father_plmtype='document'"], :class_name => "Document"
		father.belongs_to :part_up , :conditions => ["father_plmtype='part'"], :class_name => "Part"
		father.belongs_to :project_up , :conditions => ["father_plmtype='project'"], :class_name => "Project"
		father.belongs_to :customer_up , :conditions => ["father_plmtype='customer'"], :class_name => "Customer"
		father.belongs_to :definition_up , :conditions => ["father_plmtype='definition'"], :class_name => "Definition"
		father.belongs_to :history_up , :conditions => ["father_plmtype='history_entry'"], :class_name => "Ruote::Sylrplm::HistoryEntry"
		father.belongs_to :link_up , :conditions => ["father_plmtype='link'"], :class_name => "Link"
		father.belongs_to :variant_up ,
		:conditions => ["father_plmtype='part' and parts.typesobject_id in (select id from typesobjects where name='VAR')"],
		:class_name => "Part"
	end

	has_many :links_link_part,
    :class_name => "Link",
    :foreign_key => "father_id",
    :conditions => { father_plmtype: 'link', child_plmtype: 'part' }

	has_many :effectivities ,
:through => :links_link_part,
:source => :effectivity_down

	###non validates_uniqueness_of :child_id, scope: [:child_plmtype, :father_id, :father_type]
	###validates :link_uniqueness, :validity
	#before_save :link_uniqueness, :validity
	before_save :validity

	def effectivities_old_voircidessus
		fname = "#{self.class.name}.#{__method__}"
		#LOG.info (fname) {"self=#{self}"}
		ret=[]
		::Link.find(:all,
		:conditions => ["father_plmtype='link' and child_plmtype='part' and father_id = #{self.id}"]
		).each do |lnk|
			LOG.debug(fname) {"lnk=#{lnk.ident} child.type=#{lnk.child.typesobject.name}"}
			if lnk.child.typesobject.name == 'EFF'
			ret << lnk.child
			end
		end
		ret
	end

	def initialize_essai(*args)
		fname= "link:#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"initialize args=#{args.length}:#{args.inspect}"}
		super
		if args.size>0
			unless args[0].nil? || args[0][:father].nil? || args[0][:child].nil?
				father_plmtype=args[0][:father].model_name
				father_id=args[0][:father].id
				child_plmtype=args[0][:child].model_name
				child_id=args[0][:child].id
			end
		end
	end

	""

	# in fact, this is not useful to test uniqueness here, the cardinality permit to have several links identicals
	#
	def link_uniqueness_obsolete
		fname = "#{self.class.name}.#{__method__}"
		ret=true
		cond = ["father_plmtype = ? and child_plmtype = ? and father_id = ? and child_id = ? and relation_id = ? ",
			father_plmtype, child_plmtype, father_id, child_id, relation_id]
		unless ::Link.find(:first, :conditions => cond).nil?
			self.errors.add_to_base('Link already exists!')
		ret=false
		end
		LOG.debug (fname) {"link_uniqueness '#{self}' #{cond} = #{ret}"}
		ret
	end

	def designation
		""
	end

	def before_save
		fname = "#{self.class.name}.#{__method__}"
		self.domain = father.domain if father.respond_to?(:domain)
		self.domain = child.domain if (self.domain.nil? && child.respond_to?(:domain))
		LOG.debug (fname) {"before_save:self=#{self}"}
	end

	def user=(user)
		def_user(user)
	end

	def validity
		fname = "#{self.class.name}.#{__method__}"
		begin
		#LOG.info(fname) {"father.typesobject=#{father.typesobject} relation.father_typesobject=#{relation.father_typesobject}"}
		#LOG.info(fname) {"child.typesobject=#{child.typesobject} relation.child_typesobject=#{relation.child_typesobject}"}
			msg="relation.father_plmtype:'#{relation.father_plmtype}' <> (father_plmtype:'#{father_plmtype}' and '#{PlmServices.get_property(:PLMTYPE_GENERIC)}')"
			valid = (father_plmtype == relation.father_plmtype || relation.father_plmtype == PlmServices.get_property(:PLMTYPE_GENERIC))
			if valid
				msg="relation.child_plmtype:'#{relation.child_plmtype}' <> (child_plmtype:'#{child_plmtype}' and '#{PlmServices.get_property(:PLMTYPE_GENERIC)}')"
				valid =(child_plmtype == relation.child_plmtype || relation.child_plmtype == PlmServices.get_property(:PLMTYPE_GENERIC))
				if valid
					if father.respond_to? :typesobject
						msg="relation.father_type:'#{relation.father_typesobject}' <> (father.type:'#{father.typesobject}' and '#{PlmServices.get_property(:TYPE_GENERIC)}')"
						valid = (father.typesobject.name==relation.father_typesobject.name || relation.father_typesobject.name == PlmServices.get_property(:TYPE_GENERIC))
					end
					if valid
						if child.respond_to? :typesobject
							msg="relation.child_type:'#{relation.child_typesobject}' <> (child.type:'#{child.typesobject}' and '#{PlmServices.get_property(:TYPE_GENERIC)}')"
							valid = (child.typesobject.name==relation.child_typesobject.name || relation.child_typesobject.name == PlmServices.get_property(:TYPE_GENERIC))
						end
					end
				end
			end
			unless valid
				self.errors.add("Link is not valid:<br/>#{msg}")
			end
		rescue Exception => e
			valid = false
			msg="Exception during link validity test:"
			msg+="<br/>exception=#{e}"
		self.errors.add(msg)
		end
		LOG.debug (fname) {"validity '#{self}' =#{valid} msg=#{msg}"}
		valid
	end

	def cardinality_count
		nb_used = self.class.nb_used(relation)
		unless nb_used >= relation.cardin_use_min && (relation.cardin_use_max == -1 || nb_used <= relation.cardin_use_max)
			self.errors.add_to_base('Cardinality is not valid!')
		end
	end

	def father
		fname = "#{self.class.name}.#{__method__}"
		#LOG.debug (fname) {"father_plmtype=#{father_plmtype} father_id=#{father_id}"}
		get_object(father_plmtype, father_id) unless father_plmtype.blank? || father_id.blank?
	end

	def father_ident
		fname = "#{self.class.name}.#{__method__}"
		ret=""
		unless father.nil?
			ret  = "#{father_id}:#{father.model_name}"
			if father.respond_to? :typesobject
				ret += "#{father.typesobject}"
			else
				msg=I18n.t(:database_not_consistency, :msg=>"#{father} has no type !")
				LOG.error("Error on:#{self.inspect}")
				LOG.error("Error:#{msg}")
			ret += ::Typesobject::NO_TYPE
			end
			ret += "=#{father.ident_plm}"
		else
			msg=I18n.t(:database_not_consistency, :msg=>" no child !")
			LOG.error("Error on:#{self.inspect}")
			LOG.error("Error:#{msg}")
		ret += ::Link::NO_FATHER
		end
	end

	def child
		get_object(child_plmtype, child_id) unless child_plmtype.blank? || child_id.blank?
	end

	def child_ident
		fname = "#{self.class.name}.#{__method__}"
		ret=""
		unless child.nil?
			ret  = "#{child_id}:#{child.model_name}"
			if child.respond_to? :typesobject
				ret += "#{child.typesobject}"
			else
				msg=I18n.t(:database_not_consistency, :msg=>"#{child} has no type !")
				LOG.error("Error on:#{self.inspect}")
				LOG.error("Error:#{msg}")
			ret += ::Typesobject::NO_TYPE
			end
			ret += "=#{child.ident_plm}"
		else
			msg=I18n.t(:database_not_consistency, :msg=>" no child !")
			LOG.error("Error on:#{self.inspect}")
			LOG.error("Error:#{msg}")
		ret += ::Link::NO_CHILD
		end
	end

	def father=(afather)
		fname = "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"afather=#{afather}"}
		self.father_plmtype=afather.model_name
		self.father_id=afather.id
	end

	def child=(achild)
		fname = "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"achild=#{achild}"}
		self.child_plmtype=achild.model_name
		self.child_id=achild.id
	end

	def relation=(relation)
		fname = "#{self.class.name}.#{__method__}"
		LOG.debug (fname) {"relation.type=#{relation.typesobject}, fields=#{relation.typesobject.fields}"}
		#TODO pour eviter super: no superclass method `relation=' for #<Link:0x9aceec4> super
		self.type_values = relation.typesobject.fields
		self.relation_id = relation.id
	end

	def user=(user)
		def_user(user)
	end

	def relation_ident
		begin
			rel = Relation.find(self.relation_id) unless self.relation_id.nil?
			relation_id.to_s + (rel.ident unless rel.nil?)
		rescue
			relation_id.to_s
		end
	end

	#
	# return the identifier of the link
	#
	def ident
		"#{(father.nil? ? "father null" : father.ident_plm)}-#{(relation.nil? ? "relation null" : relation.ident)}-#{(child.nil? ? "child null" : child.ident_plm)}-#{type_values}"
	end

	#
	# return the list of mdlid attribute of all effectivities
	#
	def effectivities_mdlid
		@effectivities_mdlid ||= effectivities.map(&:mdlid)
	end

	#
	#menage des effectivites non presentes dans effs_mdlid
	#argum effectivities_mdlids : list of effectivities to keep, ex [part.24, part.22]
	#
	def clean_effectivities(effectivities_mdlids)
		fname = "#{self.class.name}.#{__method__}"
		LOG.info (fname) { "effectivities_mdlids: #{effectivities_mdlids}" }
		links_link_part.each do |current_link_effectivity|
		####LOG.info (fname) { "current_link_effectivity=#{current_link_effectivity.ident} : #{current_link_effectivity.child.mdlid}" }
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
			if self.type_values.nil?
			fields = rel.typesobject.fields
			self.type_values = fields unless fields.nil?
			#LOG.info (fname) {"#{fields} : #{self.type_values}"}
			end
		end
	end

	def type
		"link"
	end

	def update_link(user, params_link)
		update_accessor(user)
		update_attributes(params_link)
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
		raise Exception.new "Don't use this method Link.valid?"
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
		fname=self.class.name+"."+__method__.to_s+":"
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
				ret<<lnk if lnk.relation.name==relation_name
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

	def self.find_fathers(child, father_plmtype=nil)
		unless father_plmtype.nil?
			cond="child_plmtype='#{child.model_name}' and child_id =#{child.id} and father_plmtype='#{father_plmtype}'"
		else
			cond="child_plmtype='#{child.model_name}' and child_id =#{child.id}"
		end
		find(:all,
    :conditions => [cond],
    :order=>"child_id")
	end

	def self.get_all_fathers(child)
		fname=self.class.name+"."+__method__.to_s+":"
		child_plmtype=child.model_name
		cond="child_plmtype='#{child_plmtype}' and child_id =#{child.id}"
		ret=find(:all,
    :conditions => [cond],
    :order=>"child_id")
		#puts name+child_plmtype+" cond="+cond+":"+ret.inspect
		ret
	end

	def self.find_by_father_plmtype(plmtype)
		fname=self.class.name+"."+__method__.to_s+":"
		#puts name+plmtype
		links = find(:all,
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
		fname="#{self.class.name}.#{__method__}"
		if obj.respond_to? :typesobject
			unless obj.typesobject.nil?
				relation_recent_action = ::Relation.find_by_name(::SYLRPLM::RELATION_RECENT_ACTION)
				cond="child_plmtype = '#{obj.model_name}' and child_id = #{obj.id} and relation_id !=#{relation_recent_action.id}"
				ret = find(:all,
    :conditions => [cond] )
				LOG.debug "linked cond=#{cond} nb=#{ret.count}"
				ret.each do |lnk|
					LOG.debug "linked link=#{lnk.ident}"
				end
			ret.count>0
			else
				LOG.error (fname) {"DATABASE_CONSISTENCY_ERROR: no type for #{obj.ident_plm}"}
			false
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
	#    if @customer.save
	#		  lnk_orig = Link.find(lnkid)
	#			#puts "=========================lnk_orig="+lnk_orig.inspect
	#			lnk_new = lnk_orig.duplicate(new_obj, user)
	# === Result
	# 	the duplicate object , all characteristics of the object are copied excepted the followings:
	# * +new_father+ become the father of the new link
	# * +responsible/group/projowner+ : the accessor is the user
	# == Impact on other components
	#
	def duplicate(new_father, user)
		fname="#{self.class.name}.#{__method__}"
		#LOG.info (fname) {"new_father=#{new_father.inspect}"}
		ret = self.clone
		#ret.father_plmtype=new_father.model_name
		ret.father_id = new_father.id
		ret.def_user(user)
		#LOG.info (fname) {"new link=#{ret.inspect}"}
		ret
	end
end
