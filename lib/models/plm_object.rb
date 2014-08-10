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
			ret = (brev == true && has_attribute?("revision") && self.statusobject.revise_id==1) unless self.statusobject.nil?
			#LOG.debug (fname){"#{self}:#{self.model_name.upcase}_REVISE=#{brev}: status=#{self.statusobject.revise_id}:#{ret}"}
			ret
		end

		def revise_by_action?
			fname= "#{self.model_name}.#{__method__}"
			brev=PlmServices.get_property("#{self.model_name.upcase}_REVISE")
			ret = brev == true && has_attribute?("revision") && self.statusobject.revise_id==2 unless self.statusobject.nil?
			#LOG.debug (fname){"#{self}:#{self.model_name.upcase}_REVISE=#{brev}: status=#{self.statusobject.revise_id}:#{ret}"}
			ret
		end

		def revise
			fname= "#{self.model_name}.#{__method__}"
			#LOG.debug (fname){"#{self.ident}"}
			# recherche si c'est la derniere revision
			rev_cur = self.revision
			last_rev = last_revision
			if revisable?
				admin = User.find_by_name(PlmServices.get_property(:ROLE_ADMIN))
				obj = self.clone
				obj.set_default_values_without_next_seq
				obj.statusobject = ::Statusobject.get_first(self)
				obj.revision = next_revision
				LOG.debug (fname){"#{self.ident} rev=#{obj.inspect}"}
				if self.has_attribute?(:filename)
					if(self.filename!=nil)
					content = self.read_file
					obj.write_file(content)
					end
				end
				st = obj.save
				if !st
					obj = nil
				else
				st = obj.from_revise(self)
				end
			return obj
			else
				LOG.debug (fname){"#{self.ident} not revisable"}
				return nil
			end
		end

		def next_revision
			fname= "#{self.model_name}.#{__method__}"
			next_revision = self.revision
			found = false
			modl = eval self.class.name
			while found == false
				next_revision = next_revision.next
				obj=nil
				begin
					LOG.debug (fname){"find_by_ident_and_revision"}
					obj = modl.find_by_ident_and_revision(self.ident, next_revision)
					if obj.nil?
					found = true
					end
				rescue Exception=>e
				found = true
				end
			end
			next_revision
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
			deja=false
			if ret && choice==3
			# by action, test if a process already started for the same action on the object
			###deja = Ruote::Sylrplm::Process.exists_on_object_for_action?(self, "promote")
			###ret = !deja
			end
			###LOG.debug (fname) { "#{self.ident} choice=#{choice} deja=#{deja} ret=#{ret}"}
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
			ret=[]
			unless self.statusobject.nil?
				nexts = self.statusobject.next_statusobjects
				if nexts.size >0
					ret="promote_by_select" if promote_by_select?
					ret="promote_by_menu" if promote_by_menu?
					ret="promote_by_action" if promote_by_action?
				end
				#puts "promote_button?:nexts.size=#{nexts.size} by_select?=#{promote_by_select?} by_menu?=#{promote_by_menu?} by_action?=#{promote_by_action?} ret=#{ret}"
			end
			ret
		end

		def demote_button?
			ret=[]
			unless self.statusobject.nil?
				prevs = self.statusobject.previous_statusobjects
				if prevs.size > 0
					ret="demote_by_select" if demote_by_select?
					ret="demote_by_menu" if demote_by_menu?
					ret="demote_by_action" if demote_by_action?
				end
				#puts "demote_button?:prevs.size=#{prevs.size} by_select?=#{demote_by_select?} by_menu?=#{demote_by_menu?} by_action?=#{demote_by_action?} ret=#{ret}"
			end
			ret
		end

		def revise_button?
			ret="revise_by_menu" if revise_by_menu?
			ret="revise_by_action" if revise_by_action?
			ret
		end

		def promote
			fname= "#{self.class.name}.#{__method__}"
			st_cur_name = statusobject.name
			LOG.info (fname) {"st_cur_name=#{st_cur_name} next_status=#{self.next_status}"}
			#self.statusobject=::Statusobject.find(self.next_status_id)
			unless self.next_status.nil?
			self.statusobject=self.next_status
			#puts "Document.promote:res=#{res}:#{st_cur_name}->#{statusobject.name}"
			else
				raise Exception.new("Error during promotion: Next status not found")
			end
			self.next_status=nil
			ret = self
			#puts "object.promote:#{st_cur_name} -> #{self.statusobject.name} ret=#{ret}"
			ret
		end

		def demote
			st_cur_name = self.statusobject.name
			stid = self.previous_status_id
			#self.statusobject=::Statusobject.find(self.previous_status_id)
			unless self.previous_status.nil?
			self.statusobject=self.previous_status
			else
				raise Exception.new("Error during demote: Previous status not found")
			end
			self.previous_status=nil
			ret = self
			#puts "object.demote:#{st_cur_name} -> #{self.statusobject.name} ret=#{ret}"
			ret
		end

		def relations(child_plmtype = nil)
			::Relation.relations_for(self, child_plmtype)
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

		def initialize(*args)
			fname= "#{self.class.name}.#{__method__}"
			#LOG.info (fname) {"args=#{args.length}:#{args.inspect}"}
			super
			if self.respond_to? :revision
				if args.size>0 && !args[0].nil? && (!args[0].include?(:revision))
					self.revision = "1"
				end
			end

			if (self.respond_to? :typesobject)
				if args.size>0 && !args[0].nil? && (!args[0].include?(:typesobject_id))
				self.typesobject = ::Typesobject.get_default(self)
				end
			end

			if (self.respond_to? :statusobject)
				if args.size>0 && !args[0].nil? && (!args[0].include?(:statusobject_id))
				self.statusobject = ::Statusobject.get_first(self)
				end
			end

			if args.size>0
				unless args[0].nil? || args[0][:user].nil?
					self.set_default_values_with_next_seq
					if (self.respond_to? :statusobject)
					# recalculate the status here because depending of the type modified above
					self.statusobject = ::Statusobject.get_first(self)
					end
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

		def remove_datafile(item)
			self.datafiles.delete(item)
		end

		def get_datafiles
			ret = []
			ret = self.datafiles
			ret = { :recordset => ret, :total => ret.length }
			ret
		end

	end
end