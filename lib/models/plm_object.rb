require 'ruote/sylrplm/workitems'

module Models
	module PlmObject
		# modifie les attributs avant edition
		def self.included(base)
			base.extend(ClassMethods)
		# a appelle extend du sous module ClassMethods sur "base", la classe dans laquelle tu as inclue la lib
		end

		module ClassMethods
			# inutilisee, voir application_controller.get_models_and_columns
			def self.get_columns
				ret=[]
				self.content_columns().each do |col|
					if(col.name != 'created_at' && col.name != 'updated_at' && col.name != 'owner')
					ret<<col.name
					end
				end
				ret
			end
		end

		def edit()
			self.date=DateTime::now()
		end

		def is_freeze_old
			if(self.statusobject!=nil && ::Statusobject.get_last(self)!=nil)
				if(self.statusobject.rank == ::Statusobject.get_last(self).rank)
				true
				else
				false
				end
			else
			false
			end
		end

		def checkout_needed?
			false
		end

		def checked?
			check = ::Check.get_checkout(self)
			#file=self.filename
			if check.nil?
			#non reserve
			false
			else
			#reserve
			true
			end
		end

		def last_revision
			fname= "#{self.model_name}.#{__method__}"
			cls=eval self.class.name
			cls.find(:last, :order=>"revision ASC",  :conditions => ["ident = '#{ident}'"])
		end

		def first_revision
			cls=eval self.class.name
			cls.find(:first, :order=>"revision ASC",  :conditions => ["ident = '#{ident}'"])
		end

		def last_revision?
			ret = (self.revision == self.last_revision.revision)
			ret
		end

		def revisable?
			###ret = (has_attribute?("revision") && frozen? && last_revision?)
			ret = revise_by_menu? || revise_by_action?
			ret
		end

		#
		# TODO solution d'attente, on teste juste que l'objet est revisionnable
		# on suppose donc qu'un process existe
		#
		def revise_by_menu?
			fname= "#{self.model_name}.#{__method__}"
			brev=PlmServices.get_property("#{self.model_name.upcase}_REVISE")
			ret = brev == true && has_attribute?("revision") && self.statusobject.revise_id==1
			LOG.debug (fname){"#{self}:#{self.model_name.upcase}_REVISE=#{brev}: status=#{self.statusobject.revise_id}:#{ret}"}
			ret
		end

		def revise_by_action?
			fname= "#{self.model_name}.#{__method__}"
			brev=PlmServices.get_property("#{self.model_name.upcase}_REVISE")
			ret = brev == true && has_attribute?("revision") && self.statusobject.revise_id==2
			LOG.debug (fname){"#{self}:#{self.model_name.upcase}_REVISE=#{brev}: status=#{self.statusobject.revise_id}:#{ret}"}
			ret
		end

		def revise
			fname= "#{self.model_name}.#{__method__}"
			#LOG.debug (fname){"#{self.ident}"}
			#if(self.frozen?)
			#LOG.debug (fname){"#{self.ident} frozen"}
			# recherche si c'est la derniere revision
			rev_cur = self.revision
			last_rev = last_revision
			if revisable?
				admin = User.find_by_name(PlmServices.get_property(:ROLE_ADMIN))
				obj = self.clone
				obj.set_default_values_without_next_seq
				obj.statusobject = ::Statusobject.get_first(self)
				obj.revision = rev_cur.next
				LOG.debug (fname){"#{self.ident} frozen revisable:#{obj.inspect}"}
				if self.has_attribute?(:filename)
					if(self.filename!=nil)
					content = self.read_file
					obj.write_file(content)
					end
				end
			return obj
			else
				LOG.debug (fname){"#{self.ident} frozen not revisable"}
				return nil
			end
		#else
		#	LOG.debug (fname){"#{self.ident} not frozen"}
		#	return nil
		#end
		end

		# a valider si avant dernier status
		def could_validate?
			mdl = model_name
			!(self.statusobject.nil? || ::Statusobject.get_last(self).nil?) &&
			self.statusobject.rank == ::Statusobject.get_last(self).rank-1
		end

		def plm_validate
			if could_validate?
				promote
			end
		end

		def promote?
			#(self.respond_to? (:statusobject) ? self.statusobject.promote_id !=0 : false)
			fname="#{self.class.name}.#{__method__}"
			ret=false
			if self.respond_to? :statusobject
				unless  self.statusobject.nil?
					if self.statusobject.promote_id !=0
					ret = true
					end
				else
					LOG.error (fname) {"DATABASE_CONSISTENCY_ERROR: no status for #{self.ident}"}
				end
			end
			ret
		end

		def demote?
			#(self.respond_to? (:statusobject) ? self.statusobject.demote_id !=0 : false)
			fname="#{self.class.name}.#{__method__}"
			ret=false
			if self.respond_to? :statusobject
				unless  self.statusobject.nil?
					if self.statusobject.demote_id !=0
					ret = true
					end
				end
			else
				LOG.error (fname) {"DATABASE_CONSISTENCY_ERROR: no status for #{self.ident}"}
			end
			ret
		end

		def promote_by?(choice)
			fname="#{self.class.name}.#{__method__}"
			#puts "#{fname}: promote_id=#{self.statusobject.promote_id} choice#{choice} #{self.respond_to? :statusobject}"
			ret=false
			if self.respond_to? :statusobject
				unless  self.statusobject.nil?
					if self.statusobject.promote_id == choice
					ret = true
					end
				else
					LOG.error (fname) {"DATABASE_CONSISTENCY_ERROR: no status for #{self.ident}"}
				end
			end
			if ret && choice==3
				# par action
				deja = Ruote::Sylrplm::Process.exists_on_object_for_action?(self, "promote")
			ret = !deja
			end
			#puts "#{fname} #{self.ident}:#{ret}"
			ret
		end

		def demote_by?(choice)
			fname="#{self.class.name}.#{__method__}"
			#puts "#{fname}==> #{self.ident}: demote_id=#{self.statusobject.demote_id} choice#{choice} #{self.respond_to? :statusobject}"
			ret=false
			if self.respond_to? :statusobject
				unless  self.statusobject.nil?
					if self.statusobject.demote_id == choice
					ret = true
					end
				else
					LOG.error (fname) {"DATABASE_CONSISTENCY_ERROR: no status for #{self.ident}"}
				end
			end
			if ret && choice==3
				# par action
				deja = Ruote::Sylrplm::Process.exists_on_object_for_action?(self, "demote")
			ret = !deja
			end
			#puts "#{fname}<== #{ret}"
			ret
		end

		def promote_by_select?
			promote_by?(1)
		end

		def demote_by_select?
			demote_by?(1)
		end

		def promote_by_menu?
			promote_by?(2)
		end

		def demote_by_menu?
			demote_by?(2)
		end

		def promote_by_action?
			promote_by?(3)
		end

		def demote_by_action?
			demote_by?(3)
		end

		def promote_button?
			nexts = self.statusobject.next_statusobjects
			if nexts.size >0
				ret="promote_by_select" if promote_by_select?
				ret="promote_by_menu" if promote_by_menu?
				ret="promote_by_action" if promote_by_action?
			end
			puts "promote_button?:nexts.size=#{nexts.size} by_select?=#{promote_by_select?} by_menu?=#{promote_by_menu?} by_action?=#{promote_by_action?} ret=#{ret}"
			ret
		end

		def demote_button?
			prevs = self.statusobject.previous_statusobjects
			if prevs.size > 0
				ret="demote_by_select" if demote_by_select?
				ret="demote_by_menu" if demote_by_menu?
				ret="demote_by_action" if demote_by_action?
			end
			puts "demote_button?:prevs.size=#{prevs.size} by_select?=#{demote_by_select?} by_menu?=#{demote_by_menu?} by_action?=#{demote_by_action?} ret=#{ret}"
			ret
		end

		def revise_button?
			ret="revise_by_menu" if revise_by_menu?
			ret="revise_by_action" if revise_by_action?
			ret
		end

		def promote
			st_cur_name = statusobject.name
			self.statusobject=::Statusobject.find(self.next_status_id)
			#puts "Document.promote:res=#{res}:#{st_cur_name}->#{statusobject.name}"
			self.next_status=nil
			ret = self
			#puts "object.promote:#{st_cur_name} -> #{self.statusobject.name} ret=#{ret}"
			ret
		end

		def demote
			st_cur_name = self.statusobject.name
			stid = self.previous_status_id
			self.statusobject=::Statusobject.find(self.previous_status_id)
			self.previous_status=nil
			ret = self
			#puts "object.demote:#{st_cur_name} -> #{self.statusobject.name} ret=#{ret}"
			ret
		end

		def relations
			Relation.relations_for(self)
		end

		def link_relation
			if link_attributes["relation"] == ""
				""
			else
				link_attributes["relation"].name
			end
		end

		def get_workitems
			ret = []
			links = ::Link.find_fathers(self.model_name, self,  "ar_workitem")
			#puts "plm_object.get_workitems:links="+links.inspect
			links.each do |link|
				begin
					father = Ruote::Sylrplm::ArWorkitem.find(link.father_id) unless Ruote::Sylrplm::ArWorkitem.count(link.father_id)==1
					#puts "plm_object.get_workitems:workitem="+father.inspect
					father.link_attributes={"relation"=>link.relation}
					ret << father
				rescue Exception => e
				#puts "plm_object.get_workitems:erreur="+e.inspect
					LOG.info "plm_object.get_workitems:erreur="+e.inspect
				end
			end
			#puts "plm_object.get_workitems:ret="+ret.inspect
			ret
		end

		def get_histories
			ret = []
			links = ::Link.find_fathers(self.model_name, self,  "history_entry")
			links.each do |link|
				begin
					father = Ruote::Sylrplm::HistoryEntry.find(link.father_id) unless Ruote::Sylrplm::HistoryEntry.count(link.father_id)==1
					#puts "plm_object.get_histories:history="+father.inspect
					father.link_attributes={"relation"=>link.relation}
					ret << father
				rescue Exception => e
					puts "plm_object.get_histories:erreur="+e.inspect
					LOG.error "plm_object.get_histories:erreur="+e.inspect
				end
			end
			#puts "plm_object.get_histories:ret="+ret.inspect
			ret
		end

		def add_documents_from_favori(favori)
			favori.items.each do |item|
				documents << item
			end
		end

		def remove_documents()
			documents = nil
		end

		def remove_document(document)
			documents.delete( document)
		end

		def add_parts_from_favori(favori)
			favori.items.each do |item|
				parts << item
			end
		end

		def remove_parts()
			parts = nil
		end

		def remove_part(part)
			parts.delete( part)
		end

		def add_projects_from_favori(favori)
			favori.items.each do |item|
				projects << item
			end
		end

		def remove_projects()
			projects = nil
		end

		def remove_project(item)
			projects.delete( item)
		end

		def add_users_from_favori(favori)
			favori.items.each do |item|
				users << item
			end
		end

		def remove_users()
			users = nil
		end

		def remove_user(item)
			users.delete( item)
		end

		def self.find_all
			find(:all, :order=>"ident")
		end

		def self.find_others(object_id)
			find(:all,
    :conditions => ["id != #{forobject_id}"],
    :order=>"ident")
		end

		# si meme groupe ou confidentialite = public ou confidentiel
		def ok_for_index?(user)
			acc_public = ::Typesobject.find_by_forobject_and_name("project_typeaccess", "public")
			acc_confidential = ::Typesobject.find_by_forobject_and_name("project_typeaccess", "confidential")
			#puts "ok_for_index?:acc_public="+acc_public.inspect
			#puts "ok_for_index?:acc_confidential="+acc_confidential.inspect
			#puts "ok_for_index?:self="+self.inspect
			#puts "ok_for_index?:user="+user.inspect
			#index possible meme sans user connecte
			puts "ok_for_index? acc_public:"+self.projowner.typeaccess.name+"=="+acc_public.name
			puts "ok_for_index? acc_confidential:"+self.projowner.typeaccess.name+"=="+acc_confidential.name
			unless user.nil?
				puts "ok_for_index? group:"+self.group.name+"=="+user.group.name
			(self.group_id==user.group.id || self.projowner.typeaccess_id==acc_public.id || self.projowner.typeaccess_id==acc_confidential.id)
			else
			(self.projowner.typeaccess_id==acc_public.id || self.projowner.typeaccess_id==acc_confidential.id)
			end
			true
		end

		# si meme groupe ou confidentialite = public
		def ok_for_show?(user)
			acc_public = ::Typesobject.find_by_forobject_and_name("project_typeaccess", "public")
			#index possible meme sans user connecte
			#puts "ok_for_show? acc_public:"+self.projowner.typeaccess.name+"=="+acc_public.name
			unless user.nil?
			#puts "ok_for_show? group:"+self.group.name+"=="+user.group.name
			(self.group_id==user.group.id || self.projowner.typeaccess_id==acc_public.id)
			else
			(self.projowner.typeaccess_id==acc_public.id)
			end
		end

		def before_destroy
			#unless Favori.get(self.model_name).count.zero?
			#  raise "Can't delete because of links:"+self.ident
			#end
			if ::Link.linked?(self)
				#raise "Can't delete "+self.ident+" because of links:"
				self.errors.add_to_base "Can't delete "+self.ident+" because of links"
			return false
			end
		end

		def def_user(user)
			fname= "#{self.class.name}.#{__method__}"
			LOG.info (fname) {"user=#{user.inspect} "}
			unless user.nil?
				#LOG.info (fname) {"user=#{user.ident} "}
				if self.respond_to? :owner
				self.owner = user
				#LOG.info (fname) {"owner=#{self.owner.ident}"}
				end
				if self.respond_to? :group
				self.group     = user.group
				#LOG.info (fname) {"group=#{self.group.ident}"}
				end
				if self.respond_to? :projowner
				self.projowner = user.project
				#LOG.info (fname) {"projowner=#{self.projowner.ident}"}
				end
				if self.respond_to? :domain
				self.domain = user.session_domain
				#LOG.info (fname) {"domain=#{self.domain}"}
				end
			end
		#LOG.info (fname) {"self=#{self.inspect}"}
		end

		def initialize(*args)
			fname= "#{self.class.name}.#{__method__}"
			LOG.info (fname) {"args=#{args.length}:#{args.inspect}"}
			super
			if self.respond_to? :revision
				if args.size>0 && (!args[0].include?(:revision))
					self.revision = "1"
				end
			end

			if (self.respond_to? :statusobject)
				if args.size>0 && (!args[0].include?(:statusobject_id))
				self.statusobject = ::Statusobject.get_first(self)
				end
			end

			if args.size>0
				unless args[0][:user].nil?
					self.set_default_values_with_next_seq
					if (self.respond_to? :statusobject)
					# recalculate the status here because depending of the type modified above
					self.statusobject = ::Statusobject.get_first(self)
					end
				end
			end

		end

		def before_save
			fname= "#{self.class.name}.#{__method__}"
			#LOG.debug (fname) {"***************************************"}
			if (self.respond_to? :owner) && (self.respond_to? :group)
				unless owner.nil?
					unless  owner.group.nil?
						self.group     = owner.group
					else
						self.group     = owner.groups[0]
					end
				#LOG.info (fname) {"owner=#{owner} group=#{group}"}
				end
			end
			if (self.respond_to? :owner) && (self.respond_to? :projowner)
				unless owner.nil?
					unless owner.project.nil?
						self.projowner = owner.project
					else
						self.projowner = owner.projects[0]
					end
				#LOG.info (fname) {"owner=#{owner}  projowner=#{projowner}"}
				end
			end

		end

		# identifiant informatique : model + id
		def mdlid
			model_name+"."+id.to_s
		end

		def add_datafile(params,user)
			fname= "#{self.class.name}.#{__method__}"
			LOG.info (fname){"Don't use this method but: document.datafiles.build(params[:datafile])"}
		end

		def add_datafile_old(params,user)
			datafile = Datafile.new(params)
			datafile.document = self
			if datafile.save
				self.datafiles << datafile
				self.save
				"ok"
			else
				"datafile_not_saved"
			end
		end

		def remove_datafile(item)
			self.datafiles.delete(item)
		end

		def get_datafiles
			ret = []
			ret = self.datafiles
			ret = { :recordset => ret, :total => ret.length }
			ret
		end

		# == Role: this function duplicate the object
		# == Arguments
		# * +user+ - The user which proceed the duplicate action
		# == Usage from controller or script:
		#   theObject=Customer.find(theId)
		#   theObject.duplicate(current_user)
		# === Result
		# 	the duplicate object , all characteristics of the object are copied excepted the followings:
		# * +ident+ : a new one is calculated if this is a sequence, if not, the same is proposed.
		# * +status+ : the status is reset to the first one.
		# * +revision+ : the revision is reset to the first one.
		# * +responsible/group/projowner+ : the accessor is the current user
		# * +date+ : date is the actual date
		# * +domain+ : the user domain is used (see def_user method in this Module PlmObject )
		# == Impact on other components
		#
		def duplicate(user)
			fname = "#{self.class.name}.#{__method__}"
			LOG.info (fname){"self=#{self.inspect}"}
			ret = self.clone
			ret.def_user(user)
			if ret.respond_to? :revision
				set_default_value(:revision, 0)
			end
			if (ret.respond_to? :statusobject)
			ret.statusobject = ::Statusobject.get_first(ret)
			end
			ret.set_default_value(:ident, 1)
			if (ret.respond_to? :date)
				ret.date=DateTime::now()
			end
			LOG.info (fname){"ret=#{ret.inspect}"}
			ret
		end

	end
end