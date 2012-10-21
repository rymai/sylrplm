class Link < ActiveRecord::Base
	include Models::SylrplmCommon
	#include Ruote::Sylrplm::ArWorkitem
	# une seule occurence d'un fils de type donne dans un pere de type donne
	### verif par soft dans create_new validates_uniqueness_of :child_id, :scope => [:child_plmtype, :father_id, :father_type ]
	#validates_presence_of :name

	belongs_to :relation,
    :class_name => "Relation",
    :foreign_key => "relation_id"

	belongs_to :owner,
    :class_name => "User"

	belongs_to :group

	belongs_to :projowner,
    :class_name => "Project"

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

	def effectivities_mdlid
		ret=[]
		self.effectivities.each do |eff|
			ret << eff.mdlid
		end
		ret
	end

	#menage des effectivites non presentes dans effs_mdlid: [part.24, part.22]
	def clean_eff(effs_mdlid)
		fname= "#{self.class.name}.#{__method__}"
		LOG.info (fname) {"effs_mdlid=#{effs_mdlid}"}
		links_effectivities.each do |link_eff_cur|
			LOG.info (fname) {"link_eff_cur=#{link_eff_cur.ident} : #{link_eff_cur.child.mdlid}"}
			unless effs_mdlid.include?(link_eff_cur.child.mdlid)
				LOG.info (fname) {"destroy:#{link_eff_cur.ident}"}
			link_eff_cur.destroy
			end
		end
	end

	def after_find
		fname= "#{self.class.name}.#{__method__}"
		if self.values.nil?
			fields = self.relation.typesobject.fields
			self.values = fields unless fields.nil?
			LOG.info (fname) {"#{fields} : #{self.values}"}
		end
	end

	def typesobject_id
		relation.typesobject_id
	end

	def typesobject
		relation.typesobject
	end

	def type
		"link"
	end

	# creation
	def self.create_new(father, child, relation, user)
		fname= "#{self.class.name}.#{__method__}"
		#puts "link:create_new:"+father.inspect+"-"+child.inspect+"."+child.inspect
		if valid?(father, child, relation)
			nbused = self.nb_used(relation)
			nboccured = self.nb_occured(father, relation)
			#puts "link.create_new:"+nbused.to_s+ " "+child.model_name+"."+child.typesobject.name+" utilises dans relation "+relation.ident
			#puts "link.create_new:"+nboccured.to_s+ " "+child.model_name+"."+child.typesobject.name+" occurences "+" dans "+father.ident
			if (nbused >= relation.cardin_use_min && (relation.cardin_use_max == -1 || nbused <= relation.cardin_use_max))
				obj = Link.new
				obj.father_plmtype = father.model_name
				obj.child_plmtype = child.model_name
				obj.father_typesobject_id = father.typesobject_id
				obj.child_typesobject_id = child.typesobject_id
				obj.father_id = father.id
				obj.child_id = child.id
				obj.relation_id = relation.id
				obj.values = relation.typesobject.fields
				obj.owner = user
				obj.group = user.group
				obj.projowner=user.project
				msg="ctrl_link_"+obj.ident
			else
				obj=nil
				msg=:ctrl_link_too_many_used
			end
		else
			obj=nil
			msg=:ctrl_link_not_valid
		end
		ret={:link => obj,:msg => msg}
		#puts "link.create_new:"+ret.inspect
		ret
	end

	# link creation with values
	# calls from PLMParticipant
	def self.create_new_by_values(values, user = nil)
		link = Link.new(values)
		unless user.nil?
			link.owner=current_user
			link.group=current_user.group
		end
		msg="ctrl_link_"+link.ident
		ret={:link => link,:msg => msg}
		#puts "link.create_new_by_values:"+ret.inspect
		ret
	end

	def father
		get_object(father_plmtype, father_id)
	end

	def child
		get_object(child_plmtype, child_id)
	end

	def father_ident
		ret=self.father_id.to_s+":"+self.father_plmtype+"."+self.father_typesobject_id.to_s
		ret+="="+self.father.ident unless self.father.nil?
		ret
	end

	def child_ident
		ret=self.child_id.to_s+":"+self.child_plmtype+"."+self.child_typesobject_id.to_s
		ret+="="+self.child.ident unless self.child.nil?
	end

	def relation_ident
		begin
			rel = Relation.find(self.relation_id) unless self.relation_id.nil?
			relation_id.to_s+(rel.ident unless rel.nil?)
		rescue Exception=>e
			relation_id.to_s
		end
	end

	def ident
		#father_id.to_s+":"+father_plmtype.to_s+"."+father_typesobject_id.to_s+"-"+relation_id.to_s+"-"+child_id.to_s+":"+child_plmtype.to_s+"."+child_typesobject_id.to_s
		"#{(father.nil? ? "father null" : father.ident)}-#{(relation.nil? ? "relation null" : relation.ident)}-#{(child.nil? ? "child null" : child.ident)}-#{values}"
	end

	def exists?
		fname= "#{self.class.name}.#{__method__}"
		cond="father_plmtype='#{self.father_plmtype}' and child_plmtype='#{self.child_plmtype}' and father_typesobject_id =#{self.father_typesobject_id} and child_typesobject_id =#{self.child_typesobject_id} and relation_id =#{self.relation_id}"
		nb=0
		idt = self.ident
		Link.find(:all, :conditions => [cond]).each do |link|
		#puts idt+" ==? "+self.ident
			nb += 1 if idt == link.ident
		end
		LOG.info (fname){nb.to_s+" liens identiques:"+cond}
		nb > 0
	end

	# bidouille infame car l'association ne marche pas
	def relation
		Relation.find(relation_id)
	end

	def relation_name
		(self.relation.nil? ? "nil" : self.relation.name )
	end

	def self.valid?(father, child, relation)
		fname= "Link.#{__method__}"
		LOG.info(fname) {"relation=#{relation.inspect}"}
		ret=(father.model_name==relation.father_plmtype || relation.father_plmtype == ::SYLRPLM::PLMTYPE_GENERIC) \
		&& (child.model_name==relation.child_plmtype || relation.child_plmtype == ::SYLRPLM::PLMTYPE_GENERIC) \
		&& (father.typesobject.name==relation.father_typesobject.name || relation.father_typesobject.name == ::SYLRPLM::TYPE_GENERIC) \
		&& (child.typesobject.name==relation.child_typesobject.name || relation.child_typesobject.name == ::SYLRPLM::TYPE_GENERIC)
		if ret == false
			LOG.info(fname) {father.model_name+"=="+relation.father_plmtype + \
				" "+child.model_name+"=="+relation.child_plmtype + \
				" "+father.typesobject.name+"=="+relation.father_typesobject.name +  \
				" "+child.typesobject.name+"=="+relation.child_typesobject.name }
		end
		ret
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
