# frozen_string_literal: true

# require 'ruote/sylrplm/workitems'

module Models
  module PlmObject
    public

    # modifie les attributs avant edition
    def self.included(base)
      base.extend(ClassMethods)
      # a appelle extend du sous module ClassMethods sur "base", la classe dans laquelle tu as inclue la lib
    end

    module ClassMethods
      # inutilisee, voir application_controller.get_models_and_columns
      def self.get_columns
        ret = []
        content_columns.each do |col|
          if col.name != 'created_at' && col.name != 'updated_at' && col.name != 'owner'
            ret << col.name
          end
        end
        ret
      end
    end # ClassMethods

    def edit
      self.date = DateTime.now
    end

    def checkout_needed?
      false
    end

    def checked?
      check = ::Check.get_checkout(self)
      # file=self.filename
      if check.nil?
        # non reserve
        false
      else
        # reserve
        true
      end
    end

    def last_revision
      fname = "#{modelname}.#{__method__}"
      cls = eval self.class.name
      # rails2 cls.find(:last, :order=>"revision ASC",  :conditions => ["ident = '#{ident}'"])
      cls.where("ident = '#{ident}'").order('revision ASC').last
    end

    def first_revision
      fname = "#{modelname}.#{__method__}"
      cls = eval self.class.name
      # rails2 cls.find(:first, :order=>"revision ASC",  :conditions => ["ident = '#{ident}'"])
      cls.where("ident = '#{ident}'").order('revision ASC').first
    end

    def last_revision?
      fname = "#{modelname}.#{__method__}"
      ret = (revision == last_revision.revision)
      ret
    end

    def revisable?
      fname = "#{modelname}.#{__method__}"
      # ##ret = (has_attribute?("revision") && frozen? && last_revision?)
      LOG.debug(fname) { "#{fname} revise_by_menu?=#{revise_by_menu?} revise_by_action?=#{revise_by_action?} " }
      ret = revise_by_menu? || revise_by_action?
      ret
    end

    #
    # TODO solution d'attente, on teste juste que l'objet est revisionnable
    # on suppose donc qu'un process existe
    #
    def revise_by_menu?
      fname = "#{modelname}.#{__method__}"
      ret = false
      if respond_to? :statusobject
        unless statusobject.nil?
          brev = PlmServices.get_property("#{modelname.upcase}_REVISE")
          LOG.debug(fname) { "#{fname} #{self} statusobject=#{statusobject} #{modelname.upcase}_REVISE='#{brev}'" }
          if brev
            LOG.debug(fname) { "#{fname} has_attribute?revision #{has_attribute?('revision')} revise1='#{statusobject.revise_id == 1}' " }
            if has_attribute?('revision')
              ret = true if statusobject.revise_id == 1
            end
          end
        end
      end
      ret
    end

    def revise_by_action?
      fname = "#{modelname}.#{__method__}"
      if respond_to? :statusobject
        unless statusobject.nil?
          brev = PlmServices.get_property("#{modelname.upcase}_REVISE")
          ret = (brev && has_attribute?('revision') && statusobject.revise_id == 2)
        end
      end
      ret
    end

    def revise_without_links
      revise false
    end

    # Revise the object.
    # Params
    # +with_links+:: existing links are copied on the revision
    def revise(with_links = true)
      fname = "#{modelname}.#{__method__}"
      # LOG.debug(fname){"#{self.ident}"}
      # recherche si c'est la derniere revision
      rev_cur = revision
      last_rev = last_revision
      next_rev = next_revision
      if revisable?
        LOG.debug(fname) { "rev_cur=#{rev_cur} last_rev=#{last_rev} next_rev=#{next_rev}" }
        admin = User.find_by_name(PlmServices.get_property(:ROLE_ADMIN))
        # rails2 obj = self.clone
        obj = dup
        LOG.debug(fname) { "designation origine=#{designation} revision=#{obj.designation} " }
        obj.typesobject = typesobject
        obj.statusobject = ::Statusobject.get_first(self)
        obj.revision = next_rev
        LOG.debug(fname) { "origine=#{inspect} " }
        LOG.debug(fname) { "revision=#{obj.inspect}" }
        if has_attribute?(:filename)
          unless filename.nil?
            content = read_file
            obj.write_file(content)
          end
        end
        st = obj.save
        if st
          # params={ "links"=>{"part"=>["82", "84", "85", "83"]}}
          params = nil
          st = obj.duplicate_links(params, user)
          if st
            # add the relation FROM_REVISION
            st = obj.from_revise(self)
            if st
              st = obj.clone_links(self) if with_links
            end
            end
        end
        unless st
          obj.destroy
          obj = nil
         end
        return obj
      else
        LOG.debug(fname) { "#{ident} not revisable" }
        return nil
      end
    end

    def next_revision
      fname = "#{modelname}.#{__method__}"
      revision_next = revision
      if revision_next.blank?
        LOG.error(fname) { "the object '#{self}' does not have a revision !!}" }
      else
        found = false
        modl = eval self.class.name
        while found == false
          revision_next = revision_next.next
          LOG.debug(fname) { "revision_next=#{revision_next}" }
          obj = nil
          begin
            # LOG.debug(fname){"find_by_ident_and_revision ident=#{self.ident} revision _next=#{revision_next}"}
            obj = modl.find_by_ident_and_revision(ident, revision_next)
            LOG.debug(fname) { "find_by_ident_and_revision ident=#{ident} revision_next=#{revision_next} obj=#{obj}" }
            found = true if obj.nil?
          rescue Exception => e
            found = true
          end
        end
      end
      revision_next
    end

    # si params.nil?, on duplique tous les liens
    def duplicate_links(params, _user)
      fname = "#{modelname}.#{__method__}"
      LOG.debug(fname) { "duplicate_links: params=#{params}" }
      ret = true
      if params.nil? || params['links'].nil?
        %w[document part project].each do |child_model|
          link_method = "links_#{modelname}_#{child_model}s"
          next unless respond_to? link_method
          links_to_childs = send(link_method).to_a
          links_to_childs.each do |lnk_orig|
            LOG.debug(fname) { "lnk_orig=#{lnk_orig.inspect}" }
            duplicate_link lnk_orig
          end
        end
      else
        params['links'].each do |_key, id_objs|
          id_objs.each do |lnkid|
            lnk_orig = Link.find(lnkid)
            LOG.debug(fname) { "lnk_orig=#{lnk_orig.inspect}" }
            duplicate_link lnk_orig
          end
        end
      end
    end

    def duplicate_link(lnk_orig)
      fname = "#{modelname}.#{__method__}"
      if lnk_orig.nil?
        ret = false
      else
        lnk_new = lnk_orig.duplicate(self, user)
        LOG.debug(fname) { "lnk_new=#{lnk_new.inspect}" }
        if lnk_new.nil?
          ret = false
        else
          lnk_new&.save
        end
      end
      ret
    end

    # a valider si avant dernier status
    def could_validate?
      mdl = modelname
      !(statusobject.nil? || ::Statusobject.get_last(self).nil?) &&
        statusobject.rank == ::Statusobject.get_last(self).rank - 1
    end

    def plm_validate
      promote if could_validate?
    end

    def promote?
      # (self.respond_to? (:statusobject) ? self.statusobject.promote_id !=0 : false)
      fname = "#{self.class.name}.#{__method__}"
      ret = false
      if respond_to? :statusobject
        if statusobject.nil?
          LOG.error(fname) { "DATABASE_CONSISTENCY_ERROR: no status for #{ident}" }
        else
          ret = true if statusobject.promote_id != 0
        end
      end
      ret
    end

    def demote?
      # (self.respond_to? (:statusobject) ? self.statusobject.demote_id !=0 : false)
      fname = "#{self.class.name}.#{__method__}"
      ret = false
      if respond_to? :statusobject
        unless statusobject.nil?
          ret = true if statusobject.demote_id != 0
        end
      else
        LOG.error(fname) { "DATABASE_CONSISTENCY_ERROR: no status for #{ident}" }
      end
      ret
    end

    def promote_by?(choice)
      fname = "#{self.class.name}.#{__method__}"
      # puts "#{fname}: promote_id=#{self.statusobject.promote_id} choice#{choice} #{self.respond_to? :statusobject}"
      ret = false
      if respond_to? :statusobject
        if statusobject.nil?
          LOG.error(fname) { "DATABASE_CONSISTENCY_ERROR: no status for #{ident}" }
        else
          ret = true if statusobject.promote_id == choice
        end
      end
      deja = false
      # if ret && choice==3
      # by action, test if a process already started for the same action on the object
      # ##deja = Ruote::Sylrplm::Process.exists_on_object_for_action?(self, "promote")
      # ##ret = !deja
      # end
      LOG.debug(fname) { "#{ident} choice=#{choice} ret=#{ret}" }
      ret
    end

    def demote_by?(choice)
      fname = "#{self.class.name}.#{__method__}"
      # puts "#{fname}==> #{self.ident}: demote_id=#{self.statusobject.demote_id} choice#{choice} #{self.respond_to? :statusobject}"
      ret = false
      if respond_to? :statusobject
        if statusobject.nil?
          LOG.error(fname) { "DATABASE_CONSISTENCY_ERROR: no status for #{ident}" }
        else
          ret = true if statusobject.demote_id == choice
        end
      end
      if ret && choice == 3
        # par action
        deja = Ruote::Sylrplm::Process.exists_on_object_for_action?(self, 'demote')
        ret = !deja
      end
      LOG.debug(fname) { "#{ident} choice=#{choice} ret=#{ret}" }
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
      ret = []
      unless statusobject.nil?
        nexts = statusobject.next_statusobjects
        unless nexts.empty?
          ret = 'promote_by_select' if promote_by_select?
          ret = 'promote_by_menu' if promote_by_menu?
          ret = 'promote_by_action' if promote_by_action?
        end
        # puts "promote_button?:nexts.size=#{nexts.size} by_select?=#{promote_by_select?} by_menu?=#{promote_by_menu?} by_action?=#{promote_by_action?} ret=#{ret}"
      end
      ret
    end

    def demote_button?
      ret = []
      unless statusobject.nil?
        prevs = statusobject.previous_statusobjects
        unless prevs.empty?
          ret = 'demote_by_select' if demote_by_select?
          ret = 'demote_by_menu' if demote_by_menu?
          ret = 'demote_by_action' if demote_by_action?
        end
        # puts "demote_button?:prevs.size=#{prevs.size} by_select?=#{demote_by_select?} by_menu?=#{demote_by_menu?} by_action?=#{demote_by_action?} ret=#{ret}"
      end
      ret
    end

    def revise_button?
      ret = 'revise_by_menu' if revise_by_menu?
      ret = 'revise_by_action' if revise_by_action?
      ret
    end

    def promote
      fname = "#{self.class.name}.#{__method__}"
      st_cur_name = statusobject.name
      LOG.debug(fname) { "st_cur_name=#{st_cur_name} next_status=#{next_status}" }
      LOG.debug(fname) { "self=#{inspect}" }
      # self.statusobject=::Statusobject.find(self.next_status_id)
      if next_status.nil?
        raise Exception, 'Error during promotion: Next status not found'
      else
        self.statusobject = next_status
        # puts "Document.promote:res=#{res}:#{st_cur_name}->#{statusobject.name}"
      end
      self.next_status = ::Statusobject.get_next_status(self)
      self.previous_status = ::Statusobject.get_previous_status(self)
      ret = self
      # puts "object.promote:#{st_cur_name} -> #{self.statusobject.name} ret=#{ret}"
      ret
    end

    def demote
      st_cur_name = statusobject.name
      stid = previous_status_id
      # self.statusobject=::Statusobject.find(self.previous_status_id)
      if previous_status.nil?
        raise Exception, 'Error during demote: Previous status not found'
      else
        self.statusobject = previous_status
      end
      self.next_status = ::Statusobject.get_next_status(self)
      self.previous_status = ::Statusobject.get_previous_status(self)
      ret = self
      # puts "object.demote:#{st_cur_name} -> #{self.statusobject.name} ret=#{ret}"
      ret
    end

    def relations(child_plmtype = nil, relation_type_name = nil, relation_paste_way = nil)
      fname = "#{self.class.name}.#{__method__}"
      child_type = nil
      ret = ::Relation.relations_for(self, child_plmtype, child_type, relation_type_name, relation_paste_way)
      LOG.debug(fname) { "relations from #{modelname} to #{child_plmtype}:ret=#{ret.size}" }
      ret
    end

    def link_relation
      if link_attributes['relation'] == ''
        ''
      else
        link_attributes['relation'].name
      end
    end

    def get_workitems
      fname = "#{self.class.name}.#{__method__}"
      ret = []
      ## links = ::Link.find_fathers(self.modelname, self,  "ar_workitem")
      links = ::Link.find_fathers(self, 'ar_workitem')
      # puts "plm_object.get_workitems:links="+links.inspect
      links.each do |link|
        begin
          father = Ruote::Sylrplm::ArWorkitem.find(link.father_id) unless Ruote::Sylrplm::ArWorkitem.count(link.father_id) == 1
          # puts "plm_object.get_workitems:workitem="+father.inspect
          father.link_attributes = { 'relation' => link.relation }
          ret << father
        rescue Exception => e
          # puts "plm_object.get_workitems:erreur="+e.inspect
          LOG.info 'plm_object.get_workitems:erreur=' + e.inspect
        end
      end
      LOG.debug(fname) { "get_workitems=#{ret} " }
      ret
    end

    def get_histories
      ret = []
      # #links = ::Link.find_fathers(self.modelname, self,  "history_entry")
      links = ::Link.find_fathers(self, 'history_entry')
      links.each do |link|
        begin
          father = Ruote::Sylrplm::HistoryEntry.find(link.father_id) unless Ruote::Sylrplm::HistoryEntry.count(link.father_id) == 1
          # puts "plm_object.get_histories:history="+father.inspect
          father.link_attributes = { 'relation' => link.relation }
          ret << father
        rescue Exception => e
          puts 'plm_object.get_histories:erreur=' + e.inspect
          LOG.error 'plm_object.get_histories:erreur=' + e.inspect
        end
      end
      # puts "plm_object.get_histories:ret="+ret.inspect
      ret
    end

    #
    # return all links from the object
    #
    def links_childs
      fname = "#{self.class.name}.#{__method__}"
      ret = ::Link.find_childs(self)
      LOG.debug(fname) { "childs of #{self} : #{ret}" }
      ret
    end

    def links_fathers
      fname = "#{self.class.name}.#{__method__}"
      ret = ::Link.find_fathers(self)
      LOG.debug(fname) { "fathers of #{self} : #{ret}" }
      ret
    end

    def add_documents_from_clipboard(clipboard)
      clipboard.items.each do |item|
        documents << item
      end
    end

    def remove_documents
      documents = nil
    end

    def remove_document(document)
      documents.delete(document)
    end

    def add_parts_from_clipboard(clipboard)
      clipboard.items.each do |item|
        parts << item
      end
    end

    def remove_parts
      parts = nil
    end

    def remove_part(part)
      parts.delete(part)
    end

    def add_projects_from_clipboard(clipboard)
      clipboard.items.each do |item|
        projects << item
      end
    end

    def remove_projects
      projects = nil
    end

    def remove_project(item)
      projects.delete(item)
    end

    def add_users_from_clipboard(clipboard)
      clipboard.items.each do |item|
        users << item
      end
    end

    def remove_users
      users = nil
    end

    def remove_user(item)
      users.delete(item)
    end

    def self.find_all
      find(:all, order: 'ident')
    end

    def self.find_others(_object_id)
      find(:all,
           conditions: ["id != #{forobject_id}"],
           order: 'ident')
    end

    # si meme groupe ou confidentialite = public ou confidentiel
    def ok_for_index?(user)
      acc_public = ::Typesobject.find_by_forobject_and_name('project_typeaccess', 'public')
      acc_confidential = ::Typesobject.find_by_forobject_and_name('project_typeaccess', 'confidential')
      # puts "ok_for_index?:acc_public="+acc_public.inspect
      # puts "ok_for_index?:acc_confidential="+acc_confidential.inspect
      # puts "ok_for_index?:self="+self.inspect
      # puts "ok_for_index?:user="+user.inspect
      # index possible meme sans user connecte
      puts 'ok_for_index? acc_public:' + projowner.typeaccess.name + '==' + acc_public.name
      puts 'ok_for_index? acc_confidential:' + projowner.typeaccess.name + '==' + acc_confidential.name
      if user.nil?
        (projowner.typeaccess_id == acc_public.id || projowner.typeaccess_id == acc_confidential.id)
      else
        puts 'ok_for_index? group:' + group.name + '==' + user.group.name
        (group_id == user.group.id || projowner.typeaccess_id == acc_public.id || projowner.typeaccess_id == acc_confidential.id)
      end
      true
    end

    # si meme groupe ou confidentialite = public
    def ok_for_show?(user)
      acc_public = ::Typesobject.find_by_forobject_and_name('project_typeaccess', 'public')
      # index possible meme sans user connecte
      # puts "ok_for_show? acc_public:"+self.projowner.typeaccess.name+"=="+acc_public.name
      if user.nil?
        (projowner.typeaccess_id == acc_public.id)
      else
        # puts "ok_for_show? group:"+self.group.name+"=="+user.group.name
        (group_id == user.group.id || projowner.typeaccess_id == acc_public.id)
      end
    end

    def initialize(*args)
      super(*args)
      fname = "PlmObject:#{self.class.name}.#{__method__}"
      LOG.debug(fname) { "initialize debut args=#{args.length}:#{args.inspect}" }
      initialize_(*args)
      LOG.debug(fname) { "initialize fin: self=#{inspect}" }
    end

    def after_initialize_(*args)
      fname = "PlmObject:#{self.class.name}.#{__method__}"
      LOG.debug(fname) { "after_initialize args=#{args.length}:#{args.inspect}" }
      LOG.debug(fname) { "after_initialize self=#{inspect}" }
      initialize_
    end

    def initialize_(*args)
      fname = "PlmObject:#{self.class.name}.#{__method__}"
      LOG.debug(fname) { "debut args=#{args.length}:#{args.inspect}" }
      LOG.debug(fname) { "debut : self=#{inspect}" }
      # on passe 2 fois ici: sur le new et sur le create, sur le new, le controller met le user en argument, sur le create, le controlleur met les parametres saisies
      phase_new = !(args[0].nil? || args[0][:user].nil?)
      #
      # controller:new
      #
      unless args[0].nil?
        user = args[0][:user]
        LOG.debug(fname) { "debut : phase_new={phase_new} user=#{user}" }
        def_user(user)
      end
      #
      # any case
      #
      begin
        if respond_to? :typesobject
          if !args.empty? && !args[0].nil? && !args[0].include?(:typesobject_id)
            self.typesobject_id = ::Typesobject.get_default(self).id
            LOG.debug(fname) { "initialize_ self.typesobject_id=#{typesobject_id}" }
          end
        end
        if respond_to? :statusobject
          if !args.empty? && !args[0].nil? && !args[0].include?(:statusobject_id)
            self.statusobject_id = ::Statusobject.get_first(self).id
            LOG.debug(fname) { "initialize_ self.typesobject_id=#{statusobject_id}" }
          end
        end
        if respond_to? :next_status
          if !args.empty? && !args[0].nil? && !args[0].include?(:next_status_id)
            nextst = ::Statusobject.get_next_status(self)
            self.next_status_id = nextst.id unless nextst.nil?
            LOG.debug(fname) { "initialize_ self.typesobject_id=#{next_status_id}" }
          end
        end
        if respond_to? :previous_status
          if !args.empty? && !args[0].nil? && !args[0].include?(:previous_status_id)
            prevst = ::Statusobject.get_previous_status(self)
            self.previous_status_id = prevst.id unless prevst.nil?
            LOG.debug(fname) { "initialize_ self.typesobject_id=#{previous_status_id}" }
          end
        end
        if phase_new
          # new
          set_default_values_with_next_seq
          LOG.debug(fname) { "initialize_ self apres set_default_values_with_next_seq=#{inspect}" }
          if respond_to? :statusobject
            # recalculate the status here because depending of the type modified above
            self.statusobject_id = ::Statusobject.get_first(self).id
            LOG.debug(fname) { "initialize_ self.typesobject_id=#{statusobject_id}" }
          end
        end
        LOG.debug(fname) { "initialize_ fin: type_values fin=#{type_values}" } if respond_to? :type_values
        LOG.debug(fname) { "initialize_ fin: self=#{inspect}" }
      rescue Exception => e
        err = "ERROR: #{e}"
        LOG.error(fname) { err }
      end
    end

    # identifiant informatique : model + id
    def mdlid
      modelname + '.' + id.to_s
    end

    def add_datafile(_params, _user)
      fname = "#{self.class.name}.#{__method__}"
      LOG.info(fname) { "Don't use this method but: document.datafiles.build(params[:datafile])" }
    end

    def remove_datafile(item)
      datafiles.delete(item)
    end

    def get_datafiles
      ret = []
      ret = datafiles
      ret = { recordset: ret, total: ret.length }
      ret
    end
  end
end
