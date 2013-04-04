require 'classes/plm_services'

module Models
	module SylrplmCommon
		# extend ActiveSupport::Concern # only in Rails 3.x ...
		def self.included(base)
			# ça appelle extend du sous module ClassMethods sur "base", la classe dans laquelle tu as inclu la lib
			base.extend(ClassMethods)
		end

		module ClassMethods
			def get_object_controller(model_name)
				# ajouter le 's' de fin
				model_name+"s"
			end

			#
			# partie de requetes utilisees pour les filtres des objets (index)
			#

			#
			def qry_projowner_typeaccess
				"(select typeaccess_id from projects as p where p.id = projowner_id)"
			end

			def qry_type
				"typesobject_id in (select id from typesobjects as t where t.name LIKE :v_filter)"
			end

			def qry_status
				"statusobject_id in (select id from statusobjects as s where s.name LIKE :v_filter)"
			end

			def qry_responsible_id
				"responsible_id in(select id from users where login LIKE :v_filter)"
			end

			def qry_owner_id
				"owner_id in(select id from users where login LIKE :v_filter)"
			end

			def qrys_object_ident
				"forobject_id in(select id from documents where ident LIKE :v_filter)"
			end

			def qry_author
				"author in(select id from users where login LIKE :v_filter)"
			end

			def qry_volume
				"volume_id in(select id from volumes where name LIKE :v_filter)"
			end

			def qry_role
				"role_id in(select id from roles where title LIKE :v_filter)"
			end

			def qry_forum
				"forum_id in(select id from forums where subject LIKE :v_filter)"
			end

			def qry_parent
				"parent_id in(select id from forum_items where message LIKE :v_filter)"
			end

			def truncate_words(text, len = 5, end_string = " ...")
				return if text == nil
				words = text.split()
				words[0..(len-1)].join(' ') + (words.length > len ? end_string : '')
			end

			def reset
				#cond=[]
				#objs = Link.find(:all, :conditions => [cond])
				objs=Link.all
				LOG.debug "reset:"+objs.inspect
				objs.each { |o| o.destroy }
			end

			#
			# construction de la requete de recherche simple pour toutes les vues index
			#
			def find_paginate(params)
				#puts self.model_name+"."+__method__.to_s+":debut:"+params.inspect
				#puts self.model_name+"."+__method__.to_s+":debut:"+self.class.name
				user = params[:user]
				#puts self.model_name+"."+__method__.to_s+":user="+user.inspect
				filter_access = {}
				filter_access[:qry] = ""
				filter_access[:values] = {}
				mdl = eval self.model_name
				if column_names.include?("projowner_id")
					acc_public = ::Typesobject.find_by_forobject_and_name("project_typeaccess", "public")
					acc_confidential = ::Typesobject.find_by_forobject_and_name("project_typeaccess", "confidential")
					filter_access[:qry] = ":v_acc_public_id="+qry_projowner_typeaccess+" or :v_acc_confidential_id="+qry_projowner_typeaccess
					filter_access[:values][:v_acc_public_id] = acc_public.id
					filter_access[:values][:v_acc_confidential_id] = acc_confidential.id
				else
					filter_access[:values][:v_acc_public_id] = nil
					filter_access[:values][:v_acc_confidential_id] =nil
				end
				#puts "#{self.model_name}.#{__method__}:qry=#{filter_access[:qry]}:#{filter_access[:qry].length.to_s}"
				unless user.nil? || !column_names.include?("group_id")
					filter_access[:qry] += " or " unless filter_access[:qry] == ""
					filter_access[:qry] += " group_id = :v_group_id"
					filter_access[:values][:v_group_id] = user.group.id
				end
				#puts self.model_name+".find_paginate:filter_access="+filter_access.inspect
				unless params[:query].nil? || params[:query]==""
					cond = get_conditions(params[:query])
					#puts self.model_name+".find_paginate:cond="+cond.inspect
					unless cond.nil?
						values=filter_access[:values].merge(cond[:values])
					else
						values=filter_access[:values]
					end
					if filter_access[:qry] != ""
						conditions = [filter_access[:qry]+" and ("+cond[:qry] +")", values]
					else
						conditions = [cond[:qry], values]
					end
				else
					conditions = [filter_access[:qry], filter_access[:values]]
				end
				#puts self.model_name+".find_paginate:conditions="+conditions.inspect
				#puts self.model_name+".find_paginate:page="+params[:page].to_s
				last_rev_only = false
				unless user.nil?
					if user.is_admin?
						# le user admin voit tout
						conditions = nil
					last_rev_only = false
					else
						if column_names.include?("revision")
						last_rev_only = user.last_revision
						end
					end
				end
				if last_rev_only
					# seulement la derniere revision
					select = "distinct on (ident) *"
					order="ident asc, revision desc"
					order+=","+params[:sort] unless params[:sort].nil?
					recordset = self.paginate(:page => params[:page],
					:conditions => conditions,
					:order => order,
					:select => select,
					:per_page => params[:nb_items])
				else
				# toutes les revisions
					recordset = self.paginate(:page => params[:page],
					:conditions => conditions,
					:order => params[:sort],
					:per_page => params[:nb_items])
				end

				puts self.model_name+"."+__method__.to_s+":"+recordset.inspect
				{:recordset => recordset, :query => params[:query], :page => params[:page], :total => self.count(:conditions => conditions), :nb_items => params[:nb_items], :conditions => conditions}
			end

		end

		#
		# return frozen stat of an object
		#   return:
		#     - true if status is the last of the possibles statues for this object plmtype
		#     - false in other case
		def frozen?
			fname="#{self.class.name}.#{__method__}"
			ret = false
			unless (self.statusobject.nil? || ::Statusobject.get_last(self.model_name).nil?)
				ret = (self.statusobject.rank == ::Statusobject.get_last(self.model_name).rank)
				LOG.info (fname) {"#{self.statusobject.rank} last=#{::Statusobject.get_last(self.model_name).rank}=#{ret}"}
			end
			ret
		end

		# attribution de valeurs par defaut suivant la table sequence
		# avec calcul du prochain numero de sequence si c'est une sequence
		def set_default_values_with_next_seq
			set_default_values(1)
		end

		# attribution de valeurs par defaut suivant la table sequence
		# pas de calcul du prochain numero de sequence si c'est une sequence
		def set_default_values_without_next_seq
			set_default_values(0)
		end

		def to_s
			fname = "#{self.class.name}.#{__method__}"
			ret = "#{I18n.t("ctrl_"+model_name)}"
			ret+= "/#{typesobject.name}" if self.respond_to?("typesobject") && !self.typesobject.nil?
			ret+= ".#{ident}"
			ret+= "/#{revision}" if self.respond_to?("revision")
			ret+= " #{designation}" if self.respond_to?("designation")
			ret+= " (#{statusobject.name})" if self.respond_to?("statusobject") && !self.statusobject.nil?
			##LOG.debug (fname) {"ret=#{ret}"}
			ret
		end

		def model_name
			# Part devient part
			self.class.name.downcase
		end

		def controller_name
			# Part devient parts
			self.class.name.downcase+"s"
		end

		def get_object(type, id)
			PlmServices.get_object(type, id)
		end

		def follow_up(path)
			name=self.class.name+"."+__method__.to_s+":"
			#puts name+path
			ret=[]
			if path.nil?
				path=get_path
			end
			links=Link.get_all_fathers(self)
			links.each do |lnk|
				mdl=get_model(lnk.father_plmtype)
				unless mdl.nil?
					f = mdl.find(lnk.father_id)
					p=f.get_path(lnk.relation.name)
					paths=f.follow_up(p)
					paths.each do |pp|
						ret<<path+pp
					end
				end
			end
			if ret.count==0
			ret<<path
			end
			#puts name+"end ret="+ret.inspect
			ret
		end

		def get_path(relation=nil)
			unless relation.nil?
				ret="#"+relation+":"+self.model_name+"."+self.ident
			else
			# debut de branche
				ret="$"+self.model_name+"."+self.ident
			end
			ret
		end

		def get_model(model_name)
			begin
				ret=eval model_name.camelize
			rescue Exception => e
				LOG.warn("failed to find "+model_name+" : #{e}")
				ret=nil
			end
			ret
		end

		#
		# update the object accessor before update_attributes call
		#
		def update_accessor(user)
			self.owner_id = user.id if self.attribute_present?("owner_id")
			self.group_id = user.group_id if self.attribute_present?("group_id")
			self.projowner_id = user.project_id if self.attribute_present?("projowner_id")
		end

		def to_yaml_properties
			super
			#@attributes.delete("created_at")
			#@attributes.delete("updated_at")
			#puts "to_yaml_properties:"+instance_variables.inspect
			#puts "to_yaml_properties:"+@attributes.inspect
			atts_varname = "@#{[self.class.name, self.id].join('_')}"
			instance_variable_set atts_varname, @attributes
			atts_var = instance_variable_get atts_varname
			atts_var.delete("created_at")
			atts_var.delete("updated_at")
			#puts "to_yaml_properties:"+atts_varname.to_s+"="+atts_var.inspect
			#puts "to_yaml_properties:"+atts_var.inspect
			[atts_varname]
		end

		def to_yaml_type
			#"!tag:yaml.org,2002:omap"
			[]
		end

		def to_yaml
			ret = super
			idx = ret.index("\n")
			ret = ret[idx, ret.length-idx]
			#puts "to_yaml:"+ret
			ret
		end
		#def encode_with(coder)
		#  puts "encode_with"+coder.inspect

		#atts=@attributes
		#coder["attributes"] = atts
		#coder.tag = ['!ruby/ActiveRecord', self.class.name].join(':')
		#coder.tag =["a","b"]
		#nil
		#end

		def label
			fname="#{self.class.name}.#{__method__}:"
			ret=""
			if self.respond_to?(:name)
			ret = self.name
			else if self.respond_to?(:title)
				ret = self.title
				else if self.respond_to?(:designation)
					ret = self.designation
					else
						ret = ""
					end
				end
			end
			ret="#{self.ident}:#{ret}"
			LOG.debug (fname) {"ret=#{ret}"}
			ret
		end

		def tooltip
			fname="#{self.class.name}.#{__method__}:"
			ret="#{label}(#{model_name}.#{id}"
			if self.respond_to?(:typesobject)
				unless self.typesobject.nil?
					ret += ":#{get_model(model_name).truncate_words(self.typesobject.description, 7)}"
				else
					LOG.error (fname) {"DB_CONSISTENCY_ERROR:this object has no type:#{self.inspect}"}
				end
			end
			ret+=")"
			#ret += ".#{ident}"
			ret
		end

		#private

		# determine si une colonne est modifiable ou nopn en fonction de sa definition eventuelle dans les valeurs par defaut
		# table Sequence, colonne modify
		#   - la colonne n'est pas definie dans les valeurs par defaut => readonly=false
		#   - la colonne est definie dans les valeurs par defaut
		#   	- true => readonly  = false
		#   	- false => readonly = true
		def column_readonly?(strcol)
			col = ::Sequence.find_col_for(self.class.name, strcol.to_s)
			ret=false
			unless col.nil?
			ret = !col.modify
			end
			ret
		end

		#
		# attribution de valeurs par defaut suivant la table sequence
		# @argum next_seq recherche du prochain numero de sequence si c'est une sequence
		#  - 1 avec recherche du prochain numero de sequence
		#  - 0 sans recherche du prochain numero de sequence
		def set_default_values(next_seq)
			fname = "#{self.class.name}.#{__method__}"
			LOG.debug (fname){"next_seq=#{next_seq}, model_name=#{model_name}"}
			self. attribute_names.each do |strcol|
				old_value=  self[strcol]
				col = ::Sequence.find_col_for(self.class.name, strcol)
				val = old_value
				unless col.nil?
					if col.sequence == true
						if next_seq == 1
						val = ::Sequence.get_next_seq(col.utility)
						end
					else
					val =  col.value
					end
				#LOG.debug (fname) {"#{strcol}=#{old_value} to #{val}"}
				self[strcol] = val
				end
			end
		end

	end
end
