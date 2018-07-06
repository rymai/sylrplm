# frozen_string_literal: true

# require 'classes/plm_services'

module Models
  module SylrplmCommon
    #
    # constants about type_values attribute existing on each plm object
    #
    FORMAT_DATE ||= '%Y/%m/%d:%H:%M:%S'
    TYPE_VALUES_TYPE ||= '$TYPE'
    TYPE_VALUES_VALUE ||= '$VALUE'
    TYPE_VALUES_MAXI ||= '$MAXI'
    TYPE_VALUES_MINI ||= '$MINI'
    TYPE_VALUES_TYPE_BOOLEAN ||= 'BOOLEAN'
    TYPE_VALUES_TYPE_DATE ||= 'DATE'
    TYPE_VALUES_TYPE_DECIMAL ||= 'DECIMAL'
    TYPE_VALUES_TYPE_INTEGER ||= 'INTEGER'
    TYPE_VALUES_TYPE_STRING ||= 'STRING'
    TYPE_VALUES_TYPE_TIME ||= 'TIME'
    TYPE_VALUES_TYPE_TIMESTAMP ||= 'TIMESTAMP'
    # extend ActiveSupport::Concern # only in Rails 3.x ...
    def self.included(base)
      # ça appelle extend du sous module ClassMethods sur "base", la classe dans laquelle tu as inclu la lib
      base.extend(ClassMethods)
    end

    module ClassMethods
      def get_object_controller(modelname)
        # ajouter le 's' de fin
        modelname + 's'
      end

      #
      # partie de requetes utilisees pour les filtres des objets (index)
      #

      #
      def qry_projowner_typeaccess
        '(select typeaccess_id from projects as p where p.id = projowner_id)'
      end

      def qry_type
        'typesobject_id in (select id from typesobjects as t where t.name LIKE :v_filter)'
      end

      def qry_status
        'statusobject_id in (select id from statusobjects as s where s.name LIKE :v_filter)'
      end

      def qry_responsible_id
        'responsible_id in(select id from users where login LIKE :v_filter)'
      end

      def qry_owner_id
        'owner_id in(select id from users where login LIKE :v_filter)'
      end

      def qry_object_ident
        'forobject_id in(select id from documents where ident LIKE :v_filter)'
      end

      def qry_author
        'author in(select id from users where login LIKE :v_filter)'
      end

      def qry_volume
        'volume_id in(select id from volumes where name LIKE :v_filter)'
      end

      def qry_role
        'role_id in(select id from roles where title LIKE :v_filter)'
      end

      def qry_forum
        'forum_id in(select id from forums where subject LIKE :v_filter)'
      end

      def qry_parent
        'parent_id in(select id from forum_items where message LIKE :v_filter)'
      end

      def qry_promote
        'promote_id in(select id from forum_items where message LIKE :v_filter)'
      end

      def qry_parent
        'parent_id in(select id from forum_items where message LIKE :v_filter)'
      end

      def truncate_words(text, len = 5, end_string = ' ...')
        return if text.nil?
        words = text.split
        words[0..(len - 1)].join(' ') + (words.length > len ? end_string : '')
      end

      def reset
        # cond=[]
        # objs = Link.find(:all, :conditions => [cond])
        objs = Link.all
        # LOG.debug "reset:"+objs.inspect
        objs.each(&:destroy)
      end

      #
      # construction de la requete de recherche simple pour toutes les vues index
      #
      def find_paginate(params)
        fname = "#{self.class.name}.#{__method__}"
        LOG.debug(fname) { "params=#{params}" }
        user = params[:user]
        # puts self.modelname+"."+__method__.to_s+":user="+user.inspect
        filter_access = {}
        filter_access[:qry] = ''
        filter_access[:values] = {}
        #
        # lecture possible des projets et des groupes du user
        #
        par_open = '('
        par_close = ')'
        filter_access[:qry] = par_open
        unless user.nil?
          if column_names.include?('group_id')
            filter_access[:qry] += ' group_id in ('
            user.groups.each_with_index do |group, i|
              filter_access[:qry] += group.id.to_s
              filter_access[:qry] += ',' if i < user.groups.size - 1
            end
            filter_access[:qry] += par_close
          end
          if column_names.include?('projowner_id')
            filter_access[:qry] += ' or' if filter_access[:qry] != par_open
            filter_access[:qry] += ' projowner_id in ('
            user.projects.each_with_index do |project, i|
              filter_access[:qry] += project.id.to_s
              filter_access[:qry] += ',' if i < user.projects.size - 1
            end
            filter_access[:qry] += par_close
          end
          filter_access[:qry] += par_close
        end

        # puts self.modelname+".find_paginate:filter_access="+filter_access.inspect
        LOG.debug(fname) { "filter_access=#{filter_access.inspect}" }

        if filter_access[:qry] == par_open + par_close || filter_access[:qry] == par_open || filter_access[:qry] == par_close
          filter_access[:qry] = ''
        end
        if params[:query].blank?
          conditions = [filter_access[:qry], filter_access[:values]]
        else
          cond = get_conditions(params[:query])
          LOG.debug(fname) { "apres get_conditions query=#{params[:query]}  cond=#{cond}" }
          values = if cond.nil?
                     filter_access[:values]
                   else
                     filter_access[:values].merge(cond[:values])
                   end
          conditions = if filter_access[:qry] != ''
                         [filter_access[:qry] + ' and (' + cond[:qry] + ')', values]
                       else
                         [cond[:qry], values]
                       end
        end
        LOG.debug(fname) { "apres params[query] query=#{params[:query]}  conditions=#{conditions}" }
        unless params[:filter_types].blank?
          filter_access = { qry: conditions[0], values: conditions[1] }
          # filter on object types from menus
          types_id = []
          filter_types = params[:filter_types]
          filter_types = [filter_types] unless filter_types.is_a?(Array)
          sany_type = PlmServices.get_property(:TYPE_GENERIC)
          LOG.debug(fname) { "filter_types=#{filter_types}" }
          filter_types.each do |stype|
            objtype = Typesobject.find_by_name(stype)
            LOG.debug(fname) { "objtype=#{objtype}" }
            next if objtype.nil?
            idstype = objtype.id
            LOG.debug(fname) { "stype=#{stype} sany_type=#{sany_type} , objtype=#{objtype} idstype=#{idstype}" }
            types_id << idstype unless stype == sany_type
          end
          # puts "#{self.modelname}.find_paginate:filter_types=#{filter_types} , types_id=#{types_id}"
          unless types_id.empty?
            filter_access[:qry] += ' and ' unless filter_access[:qry].blank?
            filter_access[:qry] += " typesobject_id in (#{types_id.join(',')})"
          end
          # filter_access[:values][:v_types] = "(#{types_id.join(",")})"
          conditions = [filter_access[:qry], filter_access[:values]]
        end
        LOG.debug(fname) { "apres params[:filter_types] filter_types=#{params[:filter_types]}  conditions=#{conditions}" }
        last_rev_only = false
        unless user.nil?
          if user.is_admin?
            LOG.debug(fname) { "le user admin #{user} voit tout" }
            conditions = nil
            last_rev_only = false
          else
            if column_names.include?('revision')
              last_rev_only = user.last_revision
            end
          end
        end
        LOG.debug(fname) { "apres user =#{user}  conditions=#{conditions}" }
        # unless (conditions.nil? || conditions[0].blank? || conditions[1]=={})
        if conditions.nil? || conditions[0].blank?
          # rails2 recordset = self.paginate( :page => params[:page],						:order => params[:sort],						:per_page => (params[:nb_items].nil? ? 20 : params[:nb_items])
          LOG.debug(fname) { "no conditions  sort=#{params[:sort]}" }
          recordset = order(params[:sort]).paginate(page: params[:page],
                                                    # kokoko :order=>params[:sort],
                                                    per_page: (params[:nb_items].nil? ? 20 : params[:nb_items]))
        else
          if last_rev_only
            # seulement la derniere revision
            select = 'distinct on (ident) *'
            order = 'ident asc, revision desc'
            order += ",#{params[:sort]}" unless params[:sort].nil?
            LOG.debug(fname) { "last_rev_only sort=#{order}  , select=#{select} , conditions=#{conditions}" }
            recordset = where(conditions).order(params[:sort]).paginate(page: params[:page],
                                                                         select: select,
                                                                         per_page: params[:nb_items])
          else
            # toutes les revisions
            # rails2 recordset = self.paginate( :page => params[:page],
            # rails2 :conditions => conditions,
            # rails2 :order => params[:sort],
            # rails2 :per_page => (params[:nb_items].nil? ? 20 : params[:nb_items])
            LOG.debug(fname) { "all revisions sort=#{params[:sort]}  , conditions=#{conditions}" }
            recordset = where(conditions).order(params[:sort]).paginate(page: params[:page],
                                                                        per_page: (params[:nb_items].nil? ? 20 : params[:nb_items]))

          end
        end
        # puts self.modelname+".find_paginate:conditions="+conditions.inspect
        # puts self.modelname+"."+__method__.to_s+":"+recordset.inspect
        LOG.debug(fname) { "fin conditions=#{conditions} : #{recordset.count}" }
        ret = { recordset: recordset,
                query: params[:query],
                page: params[:page],
                #TODO plantage !!    total: count(conditions: conditions),
                nb_items: params[:nb_items],
                conditions: conditions }
        LOG.debug(fname) { "ret records=#{ret[recordset].size}" } unless ret[recordset].nil?
        ret
      end

      # end of class methods
    end

    # begin of methods

    # update des attributs + des liens many (ne marche plus par update_attributes dans rails4)
    def update_attributes(params)
      fname = "#{self.class.name}.#{__method__}"
      ret = 'ok'
      params.each do |attr_name, attr_value|
        begin
          LOG.debug(fname) { "update_attribute #{attr_name} = #{attr_value}" }
          update_attribute(attr_name, attr_value) if respond_to?(attr_name)
        rescue Exception => e
          # ret=nil
          LOG.error(fname) { "Error=#{e}" }
        end
      end
      models = Dir.new("#{Rails.root}/app/models").entries
      models.each do |model_file|
        model = model_file.gsub('.rb', '')
        mdl_ids = "#{model}_ids"
        update_belong_to(params[mdl_ids], model.capitalize, "#{model}s") unless params.nil? || params[mdl_ids].nil?
      end
      ret
    end

    def update_belong_to(array_ids, model, key)
      fname = "#{self.class.name}.#{__method__}"
      belong_ = eval key.to_s
      mdl_ = eval model.to_s
      array_ids.each do |id|
        begin
          belong_ << mdl_.find(id) unless id.blank?
        rescue Exception => e
          LOG.warn(fname) { "Warning=#{e}" }
        end
      end
    end

    def decod_json(text_json, key, name)
      fname = "#{self.class.name}.#{__method__}"
      begin
        decod = ActiveSupport::JSON.decode(text_json)
        # LOG.debug(fname) {"key='#{key}' decod=#{decod} self=#{self}"}
        ret = decod
      rescue Exception => e
        LOG.error(fname) { "*****\nkey='#{key}' Error during field decoding from JSON : fields=#{text_json}\n*****" }
        LOG.error(fname) { "*****\nkey='#{key}' Error during field decoding from JSON : Exception=#{e}\n*****" }
        errors.add(:base, I18n.translate('activerecord.errors.messages.field_badly_formatted', type: name, key: key, fields: text_json, exception: e))
        ret = nil
      end
    end

    def check_type_values
      fname = "#{self.class.name}.#{__method__}"
      ret = true
      errors.clear
      if respond_to? :type_values
        objTypeValues = get_type_values
        typeFieldsValues = typesobject.get_fields_values
        LOG.debug(fname) { ">>>> check_type_values type_values=#{type_values} , objTypeValues=#{objTypeValues.inspect} , typeFieldsValues=#{typeFieldsValues.inspect}" }
        objTypeValues.each do |key, value|
          LOG.debug(fname) { "key=#{key} value=#{value}" }
          if value.nil?
            errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_not_found', key: key, value: value)
            ret = false
          else
            field = typeFieldsValues[key]
            LOG.debug(fname) { "field=#{field}" }
            if field.nil?
              errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_undefined', key: key, value: value)
              ret = false
            else
              typeField = field[TYPE_VALUES_TYPE]
              LOG.debug(fname) { "typeField=#{typeField}" }
              if typeField.nil?
                errors.add :base, I18n.translate('activerecord.errors.messages.type_values_type_badly_defined', key: key, value: value, field: field)
              else
                # all is ok, we can check the value
                typeFields = typeField.split('(')
                thetype = if typeFields.size == 2
                            typeFields[0]
                          else
                            typeField
                          end
                method = "check_type_values_#{thetype}"
                LOG.debug(fname) { "typeFields=#{typeFields} method=#{method}" }
                st = send(method, key, field, thetype, value)
                ret = false unless st
                LOG.debug(fname) { "field=#{field} $TYPE=#{typeField} method=#{method} st=#{st} ret=#{ret}" }
              end
            end
          end
        end
      end
      if errors.count > 0
        LOG.debug(fname) { "errors=#{errors.inspect} #{errors.full_messages}" }
        errors.each do |attribute, error|
          LOG.debug(fname) { "attribute=#{attribute} error=#{error}" }
        end
      end
      LOG.debug(fname) { "<<<<ret=#{ret}" }
      ret
    end

    #
    # return frozen stat of an object
    #   return:
    #     - true if ther is no next or previous status
    #     - false in other case
    #
    def frozen?
      fname = "#{self.class.name}.#{__method__}"
      if respond_to? :statusobject
        # TODO: rails4  statusobject is nil
        unless statusobject.nil?
          LOG.debug(fname) { "frozen?self=#{inspect}" }
          LOG.debug(fname) { "frozen?statusobject=#{statusobject.inspect}" }
          st_next = statusobject.next_statusobjects
          st_previous = statusobject.previous_statusobjects
        end
      end
      ret = st_next.blank? && st_previous.blank?
      # LOG.info(fname) {"st=#{statusobject.name} st_next=#{statusobject.next_statusobjects} st_previous=#{statusobject.previous_statusobjects} ret=#{ret}"}
      ret
    end

    def to_s
      # TODO: rails4
      fname = "#{self.class.name}.#{__method__}"
      LOG.debug(fname) { "self=#{inspect}" }
      ret = I18n.t('ctrl_' + modelname).to_s
      begin
        if respond_to? :typesobject
          ret += "/#{typesobject.name}" unless typesobject.nil?
        end
      rescue Exception => e
        LOG.error(fname) { "Error:#{e}" }
      end
      ret += ".#{ident}"
      ret += "/#{revision}" if respond_to? :revision
      ret += " #{designation}" if respond_to? :designation
      if respond_to? :statusobject
        ret += " (#{statusobject.name})" unless statusobject.nil?
      end
      # LOG.debug(fname) {"ret=#{ret}"}
      ret
    end

    def modelname
      fname = "#{self.class.name}.#{__method__}" + ':'
      # Part devient part
      ret = self.class.name.underscore
      ret
    end

    def controller_name
      fname = "#{self.class.name}.#{__method__}:"
      # Part devient parts
      ret = self.class.name.underscore
      ret += if self.class.name == 'Access'
               'es'
             else
               's'
             end
      # LOG.debug(fname){"controller_name:#{self.class.name} = #{ret}"}
      ret
    end

    def get_object(type, id)
      fname = "#{self.class.name}.#{__method__}" + ':'
      # LOG.debug(fname) {"type=#{type} id=#{id}"}
      PlmServices.get_object(type, id)
    end

    def follow_up(path)
      name = "#{self.class.name}.#{__method__}" + ':'
      # puts name+path
      ret = []
      path = get_path if path.nil?
      links = ::Link.get_all_fathers(self)
      links.each do |lnk|
        mdl = get_model(lnk.father_plmtype)
        next if mdl.nil?
        f = mdl.find(lnk.father_id)
        p = f.get_path(lnk.relation.name)
        paths = f.follow_up(p)
        paths.each do |pp|
          ret << path + pp
        end
      end
      ret << path if ret.count == 0
      # puts name+"end ret="+ret.inspect
      ret
    end

    def get_path(relation = nil)
      ret = if relation.nil?
              # debut de branche
              '$' + modelname + '.' + ident
            else
              '#' + relation + ':' + modelname + '.' + ident
            end
      ret
    end

    def get_model(modelname)
      begin
        ret = eval modelname.camelize
      rescue Exception => e
        LOG.warn('failed to find ' + modelname + " : #{e}")
        ret = nil
      end
      ret
    end

    #
    # update the object accessor before update_attributes call
    #
    def update_accessor(user)
      fname = "#{self.class.name}.#{__method__}"
      LOG.debug(fname) { 'debut' }
      self.owner_id = user.id if attribute_present?('owner_id')
      self.group_id = user.group_id if attribute_present?('group_id')
      self.projowner_id = user.project_id if attribute_present?('projowner_id')
      LOG.debug(fname) { 'fin' }
    end

    def to_yaml_properties
      super
      # @attributes.delete("created_at")
      # @attributes.delete("updated_at")
      # puts "to_yaml_properties:"+instance_variables.inspect
      # puts "to_yaml_properties:"+@attributes.inspect
      atts_varname = "@#{[self.class.name, id].join('_')}"
      instance_variable_set atts_varname, @attributes
      atts_var = instance_variable_get atts_varname
      atts_var.delete('created_at')
      atts_var.delete('updated_at')
      # puts "to_yaml_properties:"+atts_varname.to_s+"="+atts_var.inspect
      # puts "to_yaml_properties:"+atts_var.inspect
      [atts_varname]
    end

    def to_yaml_type
      # "!tag:yaml.org,2002:omap"
      []
    end

    def to_yaml
      ret = super
      idx = ret.index("\n")
      ret = ret[idx, ret.length - idx]
      # puts "to_yaml:"+ret
      ret
    end
    # def encode_with(coder)
    #  puts "encode_with"+coder.inspect

    # atts=@attributes
    # coder["attributes"] = atts
    # coder.tag = ['!ruby/ActiveRecord', self.class.name].join(':')
    # coder.tag =["a","b"]
    # nil
    # end

    def label
      fname = "#{self.class.name}.#{__method__}:"
      ret = ''
      ret = if respond_to?(:name)
              name
            else if respond_to?(:title)
                   title
                 else if respond_to?(:designation)
                        designation
                      else
                        ''
          end
        end
            end
      ret = if respond_to?(:ident_plm)
              "#{ident_plm}:#{ret}"
            else
              "#{ident}:#{ret}"
            end
      # LOG.debug(fname) {"ret=#{ret}"}
      ret
    end

    def tooltip
      fname = "#{self.class.name}.#{__method__}:"
      ret = "#{label}(#{modelname}.#{id}"
      if respond_to?(:typesobject)
        if typesobject.nil?
          # LOG.warn(fname) {"DB_CONSISTENCY_ERROR:this object has no type:#{self.inspect}"}
        else
          begin
            ret += ":#{get_model(modelname).truncate_words(typesobject.description, 7)}"
          rescue Exception => e
            LOG.warn(fname) { "Exception:#{e}" }
            ret += ":#{get_model(modelname)}"
          end
        end
      end
      ret += ')'
      ret
    end

    # private

    # determine si une colonne est modifiable ou nopn en fonction de sa definition eventuelle dans les valeurs par defaut
    # table Sequence, colonne modify
    #   - la colonne n'est pas definie dans les valeurs par defaut => readonly=false
    #   - la colonne est definie dans les valeurs par defaut
    #   	- true => readonly  = false
    #   	- false => readonly = true
    def column_readonly?(strcol)
      col = ::Sequence.find_col_for(self.class.name, strcol.to_s)
      ret = false
      ret = !col.modify unless col.nil?
      ret
    end

    #
    # attribution de valeurs par defaut suivant la table sequence
    # @argum next_seq recherche du prochain numero de sequence si c'est une sequence
    #  - 1 avec recherche du prochain numero de sequence
    #  - 0 sans recherche du prochain numero de sequence
    def set_default_values(next_seq)
      fname = "#{self.class.name}.#{__method__}"
      # LOG.debug(fname){"next_seq=#{next_seq}, modelname=#{modelname}"}
      attribute_names.each do |strcol|
        set_default_value(strcol, next_seq)
      end
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

    def set_default_value(strcol, next_seq)
      fname = "#{self.class.name}.#{__method__}"
      # LOG.debug(fname){"strcol=#{strcol}, next_seq=#{next_seq}, class.name=#{self.class.name}"}
      if respond_to?(strcol)
        old_value = send(strcol)
        col = ::Sequence.find_col_for(self.class.name, strcol)
        # LOG.debug(fname){"col=#{col}"}
        val = old_value
        unless col.nil?
          if col.sequence == true
            val = ::Sequence.get_next_seq(col.utility) if next_seq == 1
          else
            val = col.value
          end
          # LOG.debug(fname) {"#{strcol}=#{old_value} to #{val}"}
          self[strcol] = val
          # LOG.debug(fname) {"self=#{self.inspect}"}
        end
      end
      self
    end

    #
    # renvoie l'objet contenu dans l'attribut type_values
    #
    def get_type_values
      fname = "#{self.class.name}.#{__method__}"
      decod = {}
      if respond_to? :type_values
        LOG.debug(fname) { "#{inspect} type_value=#{type_values}" }
        unless type_values.blank?
          decod = ActiveSupport::JSON.decode(type_values)
          # puts "get_type_values:values=#{type_values} decod=#{decod}"
        end
      end
      decod
    end

    #
    # return a type value
    #
    def get_type_value(key)
      get_type_values[key]
    end

    #
    # assign type_values
    # @param hashmap of type values, examples:
    # - {"description"=>"my description"}
    #
    def set_type_values(new_type_values)
      fname = "#{self.class.name}.#{__method__}"
      unless new_type_values.blank?
        self.type_values = ActiveSupport::JSON.encode(new_type_values)
        # puts "set_type_values:values=#{type_values} "
      end
    end

    #
    # assign a type value
    #
    def set_type_value(key, value)
      fname = "#{self.class.name}.#{__method__}"
      values = get_type_values
      # puts "set_type_value:key=#{key} values=#{values} "
      values[key] = value
      set_type_values(values)
      # puts "set_type_value:key=#{key} values=#{self.type_values} "
    end

    #
    #== Role: check if the group or role is a descendant of the ancestor
    #
    # == Arguments
    # * +ancestor+ - The object to check as ancestor
    # == Usage from model or controller or script:
    #   theGroup = Group.find_by_name("SICM_BE")
    #   theAncestor = Group.find_by_name("SICM")
    #   theAdmin = Group.find_by_name("admins")
    #   theGroup.is_child_of?(theAncestor) : true
    #   theGroup.is_child_of?(theAdmin) : false
    # === Result
    # 	see above
    # == Impact on other components
    #
    def is_child_of?(ancestor)
      fname = "#{self.class.name}.#{__method__}"
      ret = false
      if respond_to? :father
        afather = father
        afather = afather.father while !afather.nil? && (afather != ancestor)
        ret = !afather.nil?
      end
      # LOG.info(fname){"self=#{self} is_child_of? #{ancestor}:#{ret}"}
      ret
    end

    #
    # this object could not have a 3d or 2d model show in tree
    #
    def have_model_design?
      false
    end

    def ident_plm
      fname = "#{self.class.name}.#{__method__}"
      ret = if respond_to? :revision
              "#{ident}/#{revision}"
            else
              ident
            end
      sep = '.'
      ret += '('
      if respond_to? :typesobject
        unless typesobject.nil?
          begin
            ret += typesobject.name
          rescue StandardError
          end
        end
      end
      if respond_to? :statusobject
        ret += sep + statusobject.name unless statusobject.nil?
      end
      ret += ')'
      LOG.info(fname) { "ident_plm=#{ret}" }
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
      LOG.info(fname) { "self avant clone=#{inspect}" }
      ret = dup
      ret.def_user(user)
      LOG.info(fname) { "ret apres clone et def_user=#{ret.inspect}" }
      ret.set_default_value(:revision, 0) if ret.respond_to? :revision
      begin
        if ret.respond_to? :statusobject
          ret.statusobject = ::Statusobject.get_first(ret)
        end
      rescue Exception => e
        # pour le cas typesobject has_many statusobject (les autres ont belong_to)
      end
      ret.set_default_value(:name, 1)
      ret.set_default_value(:title, 1)
      ret.set_default_value(:login, 1)
      ret.set_default_value(:ident, 1)
      ret.date = DateTime.now if ret.respond_to? :date
      LOG.info(fname) { "ret=#{ret.inspect}" }
      ret
    end

    def create_duplicate(object_orig)
      fname = "#{self.class.name}.#{__method__}"
      LOG.info(fname) { "object_orig:#{object_orig}" }
      st = save
      if !st
        LOG.info(fname) { "echec save:#{errors.full_messages}" }
        ret = false
      else
        st = from_duplicate(object_orig)
        ret = true
      end
      ret
    end

    def def_user(user)
      fname = "#{self.class.name}.#{__method__}"
      LOG.debug(fname) { "def_user: user=#{user.inspect} " }
      LOG.debug(fname) { "def_user: self=#{inspect} " }
      # on prend les infos du owner si le user est null
      begin
        if respond_to?(:owner)
          user = owner if user.nil?
        end
        unless user.nil?
          msg = "user=#{user.inspect} "
          if respond_to? :owner
            self.owner_id = user.id
            msg << " owner=#{owner_id}"
          end
          if respond_to? :group
            self.group_id = user.group_id
            msg << " group=#{group_id}"
          end
          if respond_to? :projowner
            self.projowner_id = user.project_id
            msg << " projowner=#{projowner_id}"
          end
          if respond_to? :domain
            self.domain = user.session_domain
            msg << " domain=#{domain}"
          end
          # datafile
          if respond_to? :volume
            self.volume_id = user.volume_id
            msg << "volume=#{volume}"
          end
        end
      rescue Exception => e
        err = "ERROR: #{e}"
        LOG.error(fname) { err }
      end
      LOG.debug(fname) { "def_user end:infos=#{msg}" }
      LOG.debug(fname) { "def_user end:self=#{inspect}" }
      self
    end

    def from_revise(from)
      from_function(from, ::Relation::RELATION_FROM_REVISION)
    end

    def from_duplicate(from)
      from_function(from, ::Relation::RELATION_FROM_DUPLICATE)
    end

    def from_function(from, function)
      fname = "#{modelname}.#{__method__}"
      LOG.debug(fname) { "from=#{from} function=#{function}" }
      rel = ::Relation.find_by_name(function)
      puts "#{fname} rel=#{rel}"
      # LOG.debug(fname){"rel=#{rel}"}
      if respond_to?(:owner)
        own = owner
        link_from = ::Link.new(father_plmtype: modelname, child_plmtype: from.modelname, father_id: id, child_id: from.id, relation_id: rel.id, owner_id: own.id)
      else
        own = nil
        link_from = ::Link.new(father_plmtype: modelname, child_plmtype: from.modelname, father_id: id, child_id: from.id, relation_id: rel.id)
      end
      st = link_from.save
      LOG.debug(fname) { "link_from=#{link_from.ident}:st save=#{st}" }
      link_from = nil unless st
      LOG.debug(fname) { "link_from=#{link_from}" }
      link_from
    end

    def clone_links(from)
      fname = "clone_links: #{modelname}.#{__method__}"
      ret = {}
      ::Link.find_childs(from).each do |link|
        LOG.debug(fname) { link.inspect.to_s }
        # rails2 newlink = link.dup
        newlink = link.dup
        newlink.father = self
        st = newlink.save
        ret[link] = (newlink if st)
      end
      ret
    end

    def have_lifecycle?
      fname = "#{modelname}.#{__method__}"
      ret = false
      if respond_to? :statusobject
        ret = true if modelname != 'typesobject'
      end
      # LOG.debug(fname){"self.modelname=#{self.modelname}  status?:#{self.respond_to? :statusobject} ret=#{ret}"}
      ret
    end

    def have_errors?
      fname = "#{modelname}.#{__method__}"
      ret = false
      unless errors.nil?
        ret = true unless errors.empty?
      end
      LOG.debug(fname) { "errors=#{errors.size} ret=#{ret}" }
      ret
    end

    #
    # adapt some atttributes of the object depending of the new type
    #
    def modify_type(type)
      fname = "#{modelname}.#{__method__}"
      typesobject_old = typesobject
      type_values_old = type_values
      self.typesobject = type
      self.type_values = type.get_fields
      if respond_to? :statusobject
        statusobject_old = statusobject
        self.statusobject = ::Statusobject.get_first(self)
        if statusobject != statusobject_old
          ret << "Status changed from #{statusobject_old} to #{statusobject}"
        end
      end
      ret = []
      if typesobject != typesobject_old
        ret << "Type changed from #{typesobject_old} to #{typesobject}"
      end
      if type_values != type_values_old
        ret << "Type_values changed from #{type_values_old} to #{type_values}"
      end

      ret
    end

    :protected

    def before_save_
      fname = "#{self.class.name}.#{__method__}"
      LOG.info(fname) { "debut before_save_ type_values=#{type_values}" } if respond_to? :type_values
      LOG.info(fname) { "debut before_save_ self=#{inspect}" }
      if (respond_to? :owner) && (respond_to? :group)
        LOG.debug(fname) { "before_save_:owner=#{owner} group=#{group}" }
        unless owner.nil?
          self.group = if owner.group.nil?
                         owner.groups[0]
                       else
                         owner.group
                       end
        end
      end
      if (respond_to? :owner) && (respond_to? :projowner)
        LOG.debug(fname) { "before_save_:owner=#{owner} projowner=#{projowner}" }
        unless owner.nil?
          if owner.project.nil?
            self.projowner = owner.projects[0]
          else
            LOG.debug(fname) { "owner.project=#{owner.project}" }
            self.projowner = owner.project
          end
        end
      end
      if (respond_to? :domain) && (respond_to? :owner)
        # LOG.debug(fname) {"domain=#{domain} admin?=#{self.owner.role.is_admin? unless self.owner.role.nil?}"}
        if domain == 'admin' && !owner.role.is_admin?
          errors.add(:base, 'Role is not admin!')
          ret = false
        end
      end
      if ret == true
        if respond_to? :typesobject
          if type_values.nil?
            fields = typesobject.get_fields
            LOG.debug(fname) { "fields=#{fields}" }
            self.type_values = fields
          end
        end
        ret = check_type_values
        if self.class.name == 'Typesobject'
          if forobject == ::SYLRPLM::PLM_PROPERTIES
            PlmServices.reset_property_cache
          end
        end
      end
      LOG.info(fname) { "fin before_save_ self=#{inspect}" }
      LOG.debug(fname) { "ret=#{ret}" }
      ret
    end

    def before_destroy_
      fname = "#{self.class.name}.#{__method__}"
      # unless Clipboard.get(self.modelname).count.zero?
      #  raise "Can't delete because of links:"+self.ident
      # end
      lnk = ::Link.linked?(self)
      LOG.debug(fname) { "before_destroy_:self=#{self} linked?=#{lnk}" }
      if lnk
        # raise "Can't delete "+self.ident+" because of links:"
        errors.add :base, "Can't delete " + ident + ' because of links'
        ret = false
      else
        ret = true
        # si besoin, destruction des liens fils, les objets correspondants seront peut etre orphelins
        childs=Link.find_childs(self)
        LOG.debug(fname) { "childs of #{self}=#{childs.count}" }
        childs.each do |child|
            st=child.destroy
            LOG.debug(fname) { "destroy child #{child}=#{st}" }
        end
      end
      ret
    end
    :private

    def check_type_values_STRING(key, field, _thetype, value)
      fname = "#{self.class.name}.#{__method__}"
      ret = true
      typeField = field[TYPE_VALUES_TYPE]
      nbc = check_length(typeField, value)
      if nbc > 0
        if value.length > nbc
          errors.add :base, I18n.translate('activerecord.errors.messages.type_values_string_too_long', key: key, value: value, nbc: nbc)
          ret = false
        end
      end

      LOG.debug(fname) { "typeField=#{typeField} nbc=#{nbc} value=#{value} ret=#{ret}" }
      ret
    end

    def check_type_values_DATE(key, field, thetype, value)
      fname = "#{self.class.name}.#{__method__}"
      ret = true
      typeField = field[TYPE_VALUES_TYPE]
      date = check_date("#{value}:10:10:10")
      if date.nil?
        ret = false
        errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_not_type', key: key, value: value, type: thetype)
        LOG.debug(fname) { "add_to_base:#{errors.size}" }
      end
      if ret
        ret = check_limits(key, thetype, value, field[TYPE_VALUES_MINI], field[TYPE_VALUES_MAXI])
      end
      LOG.debug(fname) { "typeField=#{typeField} value=#{value} date=#{(date.nil? ? 'null' : date)} ret=#{ret}" }
      ret
    end

    def check_type_values_TIME(key, field, thetype, value)
      fname = "#{self.class.name}.#{__method__}"
      ret = true
      typeField = field[TYPE_VALUES_TYPE]
      date = check_date("1970/01/01:#{value}")
      if date.nil?
        ret = false
        errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_not_type', key: key, value: value, type: thetype)
        LOG.debug(fname) { "add_to_base:#{errors.size}" }
      end
      if ret
        ret = check_limits(key, thetype, value, field[TYPE_VALUES_MINI], field[TYPE_VALUES_MAXI])
      end
      LOG.debug(fname) { "typeField=#{typeField} value=#{value} date=#{(date.nil? ? 'null' : date)} ret=#{ret}" }
      ret
    end

    def check_type_values_TIMESTAMP(key, field, thetype, value)
      fname = "#{self.class.name}.#{__method__}"
      ret = true
      typeField = field[TYPE_VALUES_TYPE]
      date = check_date(value)
      if date.nil?
        ret = false
        errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_not_type', key: key, value: value, type: thetype)
        LOG.debug(fname) { "add_to_base:#{errors.size}" }
      end
      if ret
        ret = check_limits(key, thetype, value, field[TYPE_VALUES_MINI], field[TYPE_VALUES_MAXI])
      end
      LOG.debug(fname) { "typeField=#{typeField} value=#{value} date=#{(date.nil? ? 'null' : date)} ret=#{ret}" }
      ret
    end

    def check_type_values_INTEGER(key, field, thetype, value)
      fname = "#{self.class.name}.#{__method__}"
      ret = true
      typeField = field[TYPE_VALUES_TYPE]
      begin
        ret = /\A[-+]?\d+\z/ === value
        if ret == false
          errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_not_type', key: key, value: value, type: thetype)
          LOG.debug(fname) { "add_to_base:blank #{errors.size}" }
        end
      rescue Exception => e
        ret = false
        errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_not_type', key: key, value: value, type: thetype)
        LOG.debug(fname) { "add_to_base:error #{errors.size} : #{e}" }
      end
      if ret
        ret = check_limits(key, thetype, value.to_i, field[TYPE_VALUES_MINI].to_i, field[TYPE_VALUES_MAXI].to_i)
      end
      LOG.debug(fname) { "key=#{key} field=#{field} value=#{value} ret=#{ret}" }
      ret
    end

    def check_type_values_DECIMAL(key, field, thetype, value)
      fname = "#{self.class.name}.#{__method__}"
      ret = true
      typeField = field[TYPE_VALUES_TYPE]
      LOG.debug(fname) { "typeField=#{typeField} thetype=#{thetype} value=#{value} " }
      begin
        if value !~ /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/
          ret = false
          errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_not_type', key: key, value: value, type: thetype)
          LOG.debug(fname) { "add_to_base : blank #{errors.size}" }
        else
          ret = check_precision(typeField, value)
          if ret == false
            errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_bad_format', key: key, value: value, type: thetype, fmt: typeField)
            LOG.debug(fname) { "add_to_base : check_precision #{errors.size}" }
          end
        end
      rescue Exception => e
        ret = false
        errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_not_type', key: key, value: value, type: thetype)
        LOG.debug(fname) { "add_to_base : error #{errors.size} : #{e}" }
      end
      if ret
        ret = check_limits(key, thetype, value.to_f, field[TYPE_VALUES_MINI].to_f, field[TYPE_VALUES_MAXI].to_f)
      end
      LOG.debug(fname) { "typeField=#{typeField} value=#{value}  ret=#{ret}" }
      ret
    end

    def check_type_values_BOOLEAN(key, field, thetype, value)
      fname = "#{self.class.name}.#{__method__}"
      ret = true
      typeField = field[TYPE_VALUES_TYPE]
      if value != 'true' && value != 'false' && value != 'yes' && value != 'no'
        ret = false
        errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_not_type', key: key, value: value, type: thetype)
        LOG.debug(fname) { "add_to_base:#{errors.size}" }
      end
      LOG.debug(fname) { "typeField=#{typeField} value=#{value} ret=#{ret}" }
      ret
    end

    # read the type and find the arguments:
    # param typeField the type to analyse
    # - STRING(123) : 123 is the maxi length of the string
    # - DECIMAL(5.3) : 5 characters and 3 after .
    #
    def get_typefield_args(typeField)
      fname = "#{self.class.name}.#{__method__}"
      ret = nil
      f = typeField.split('(')
      LOG.debug(fname) { "typeField=#{typeField} f=#{f}" }
      if f.size == 2
        ff = f[1].split(')')
        LOG.debug(fname) { "typeField=#{typeField} f=#{f} ff=#{ff}" }
        if ff.size == 1
          precision = ff[0].split('.')
          LOG.debug(fname) { "typeField=#{typeField}  precision=#{precision}" }
          if precision.size == 2
            nbc = precision[0].to_i
            nbdec = precision[1].to_i
            ret = [nbc, nbdec]
          else
            ret = [precision[0].to_i] if precision.size == 1
          end
        end
      end
      LOG.debug(fname) { "typeField=#{typeField} ret=#{ret}" }
      ret
    end

    def check_precision(typeField, value)
      fname = "#{self.class.name}.#{__method__}"
      args = get_typefield_args(typeField)
      nbc = args[0].to_i
      nbdec = args[1].to_i
      ret = true
      # TODO: enlever le . et le + ou -
      length = value.length
      length -= 1 unless value.index('.').nil?
      length -= 1 unless value.index('+').nil?
      length -= 1 unless value.index('-').nil?
      LOG.debug(fname) { "typeField=#{typeField} value=#{value} length=#{length}" }
      if value.length > nbc + 1
        LOG.debug(fname) { "typeField=#{typeField} value=#{value} value too long:#{value.length}>#{nbc + 1}" }
        ret = false
      else
        fv = value.split('.')
        if fv.size == 2
          if fv[1].length > nbdec
            LOG.debug(fname) { "typeField=#{typeField} value=#{value} value too much dec#{fv[1].length}>#{nbdec}" }
            ret = false
          end
        end
      end
      LOG.debug(fname) { "typeField=#{typeField} value=#{value} ret=#{ret}" }
      ret
    end

    def check_length(typeField, value)
      fname = "#{self.class.name}.#{__method__}"
      args = get_typefield_args(typeField)
      nbc = 0
      LOG.debug(fname) { "typeField=#{typeField} value=#{value} args=#{args}" }
      nbc = args[0].to_i unless args.nil?
      LOG.debug(fname) { "typeField=#{typeField} value=#{value} nbc=#{nbc}" }
      nbc
    end

    def check_date(value)
      fname = "#{self.class.name}.#{__method__}"
      begin
        date = Date.strptime(value, FORMAT_DATE)
        LOG.debug(fname) { "value=#{value} format=#{FORMAT_DATE} : date=#{date}" }
      rescue Exception => e
        date = nil
        LOG.debug(fname) { "value=#{value} format=#{FORMAT_DATE} : bad format" }
      end
      date
    end

    # test min and max
    def check_limits(key, thetype, value, min, max)
      fname = "#{self.class.name}.#{__method__}"
      ret = true
      LOG.debug(fname) { "value=#{value} min=#{min} max=#{max}" }
      unless min.blank?
        if value < min
          ret = false
          errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_outside_limit', key: key, value: value, type: thetype, sign: '<', limit: min)
        end
        LOG.debug(fname) { "add_to_base: limit #{errors.size}" }
      end
      unless max.blank?
        if value > max
          ret = false
          errors.add :base, I18n.translate('activerecord.errors.messages.type_values_value_outside_limit', key: key, value: value, type: thetype, sign: '>', limit: max)
          LOG.debug(fname) { "add_to_base: limit #{errors.size}" }
        end
      end
      LOG.debug(fname) { "value=#{value} min=#{min} max=#{max} ret=#{ret}" }
      ret
    end
  end
end
