# frozen_string_literal: true
class Document < ActiveRecord::Base
    include Models::PlmObject
    include Models::SylrplmCommon

    # ##include ActiveModel::Model

    # before_save :before_save_
    before_destroy :before_destroy_

    # after_initialize :after_initialize_

    attr_accessor :link_attributes, :user

    # ##attr_accessor :id, :revision, :typesobject_id, :designation, :description, :owner_id, :date, :ident,:owner,:group_id,:projowner_id

    # rails4: indispensable pour creer/updater
    attr_accessible :id, :revision, :typesobject_id, :statusobject_id, :next_status_id, :previous_status_id, :ident
    attr_accessible :designation, :description, :date, :domain, :type_values
    attr_accessible :owner_id, :group_id, :projowner_id

    validates_presence_of :ident, :designation
    validates_uniqueness_of :ident, scope: :revision
    # validates_format_of :ident, :with => /^(doc|img)[0-9]+$/, :message=>" doit commencer par doc ou img suivi de chiffres"
    # rails2 validates_format_of :ident, :with => /^([a-z]|[A-Z])+[0-9]+$/ #, :message=>t(:valid_ident,:typeobj =>:ctrl_document)
    validates_format_of :ident, with: /\A([a-z]|[A-Z])+[0-9]+\Z/ , :message=>"ident is not valid for document"

    belongs_to :typesobject, foreign_key: :typesobject_id
    belongs_to :statusobject, foreign_key: :statusobject_id
    belongs_to :next_status, class_name: 'Statusobject'
    belongs_to :previous_status, class_name: 'Statusobject'
    belongs_to :owner, class_name: 'User', foreign_key: :owner_id
    belongs_to :group
    belongs_to :projowner, class_name: 'Project'

    has_many :datafiles, dependent: :destroy

    # rails2 has_many :thumbnails,  	:class_name => "Datafile",  	:conditions => "typesobject_id = (select id from typesobjects as t where t.name='thumbnail')"
    has_many :thumbnails, -> { where("typesobject_id=(select id from typesobjects as t where t.name='thumbnail')") }, class_name: 'Datafile'

    has_many :checks, -> { where(checkobject_plmtype: 'document') }, foreign_type: :checkobject_plmtype, foreign_key: :checkobject_id

    # rails2 has_many :links_document_forum,    :class_name => "Link",    :foreign_key => "father_id",    :conditions => { father_plmtype: 'document', child_plmtype: 'forum' }
    has_many :links_document_forums, -> { where(father_plmtype: 'document', child_plmtype: 'forum') }, class_name: 'Link', foreign_key: 'father_id'
    has_many :forums, through: :links_document_forums, source: :forum

    # rails2 has_many :links_document_document,    :class_name => "Link",    :foreign_key => "father_id",    :conditions => { father_plmtype: 'document', child_plmtype: 'document' }
    has_many :links_document_documents, -> { where(father_plmtype: 'document', child_plmtype: 'document') }, class_name: 'Link', foreign_key: 'father_id'
    has_many :documents, through: :links_document_documents, source: :document_down

    # rails2 has_many :links_document_document_up,    :class_name => "Link",    :foreign_key => "child_id",    :conditions => { father_plmtype: 'document', child_plmtype: 'document' }
    has_many :links_document_documents_up, -> { where(father_plmtype: 'document', child_plmtype: 'document') }, class_name: 'Link', foreign_key: 'child_id'
    has_many :documents_up, through: :links_document_documents_up, source: :document_up

    has_many :parts_up,    through: :links_part_parts_up, source: :part_up

    # rails2 has_many :links_project_document_up,    :class_name => "Link",    :foreign_key => "child_id",    :conditions => { father_plmtype: 'project', child_plmtype: 'document' }
    has_many :projects_up, through: :links_project_documents_up, source: :project_up

    # rails2 has_many :links_history_document_up,    :class_name => "Link",    :foreign_key => "child_id",    :conditions => { father_plmtype: 'history_entry', child_plmtype: 'document' }
    has_many :links_history_documents_up, -> { where(father_plmtype: 'history_entry', child_plmtype: 'document') }, class_name: 'Link', foreign_key: 'child_id'
    has_many :histories_up, through: :links_history_documents_up, source: :history_up
    #
    # def persisted?
    # self.id==1
    # self.ident==1
    # self.owner==1
    # self.owner_id==1
    # end
    def user=(user)
        fname = "#{self.class.name}.#{__method__}"
        LOG.debug(fname) { "user=user=#{user}" }
        @user = user
    # def_user(user)
    end

    # essai, ok mais appelle 10 fois par document !!!
    # def after_find
    # end

    def checkout_needed?
        true
    end

    def self.get_conditions(filters)
        fname = "#{self.class.name}.#{__method__}"
        LOG.debug(fname) { "filters=#{filters}" }
        filter = filters.tr('*', '%')
        ret = {}
        unless filter.nil?
            ret[:qry] = "ident LIKE :v_filter or revision LIKE :v_filter or designation LIKE :v_filter or to_char(date, 'YYYY/MM/DD') LIKE :v_filter "
            ret[:values] = { v_filter: filter }
        end
        LOG.debug(fname) { "filters=#{filters} ret=#{ret}" }
        ret
    end

    def self.find_all
        find(:all, order: 'ident ASC, revision ASC')
    end

    def self.find_with_part
        find(:all,
         conditions: ['part_id IS NOT NULL'],
         order: 'ident')
    end

    def self.find_without_part
        find(:all,
         conditions: ['part_id IS NULL'],
         order: 'ident')
    end

    def to_s
        # TODO: rails4
        "#{try(:ident)}/#{try(:revision)}-#{try(:designation)}-#{(typesobject.nil? ? '' : typesobject.try(:name))}-#{statusobject.try(:name)}"
    end

    attr_writer :link_attributes

    attr_reader :link_attributes

    # modifie les attributs avant edition
    def self.find_edit(object_id)
        obj = find(object_id)
        obj.edit
        obj
    end

    # pour par exemple interdire les fichiers dans un répertoire
    def directory?
        !typesobject_id.nil? && ::Typesobject.find(typesobject_id).name == PlmServices.get_property(:TYPE_DOC_DIRECTORY)
    end

    def get_check_out
        Check.get_checkout(self)
    end

    def can_be_check_in?(user)
        chk = get_check_out
        ret = false
        ret = (user == chk.out_user) unless chk.nil?
        ret
    end

    def check_out(params, user)
        fname = "#{self.class.name}.#{__method__}"
        LOG.info(fname) { "params=#{params}, user=#{user.inspect}" }
        ret = get_check_out
        LOG.info(fname) { "get_checkout=#{ret}" }
        if ret.blank?
            # pas de check sur ce document, on le cree
            args = {}
            args[:out_reason] = params[:out_reason]
            args[:checkobject_plmtype] = modelname
            args[:checkobject_id] = id
            args[:user] = user
            ret = Check.create(args)
            LOG.info(fname) { "Check.create=#{ret}" }
        end
        LOG.info(fname) { "<<<<<errors=#{ret.errors.full_messages}" }
        ret = nil unless ret.errors.empty?
        ret
    end

    def check_in(params, user)
        fname = "#{self.class.name}.#{__method__}"
        ret = Check.get_checkout(self)
        if ret.nil?
            LOG.error(fname) { "pb get_checkout=#{ret}" }
        else
            ret.update_accessor(user)
            ret.checkIn(params, user)
            if ret.save
                update_attributes(params[:document])
            else
                LOG.error(fname) { "not saved=#{ret}" }
            end
            ret = nil unless ret.errors.empty?
        end

        ret
    end

    def check_free(params, user)
        fname = "#{self.class.name}.#{__method__}"
        ret = Check.get_checkout(self)
        unless ret.nil?
            ret.update_accessor(user)
            ret.checkFree(params, user)
            update_attributes(params[:document]) if ret.save
            ret = nil unless ret.errors.empty?
        end
        ret
    end

    def checked?
        return @checked if defined?(@checked)

        @checked = checks.where(status: Check::CHECK_STATUS_OUT).any?
    end

    def variants
        nil
    end

    def users
        nil
    end

    #
    # this object could have a 3d or 2d model show in tree
    #
    def have_model_design?
        true
    end
end
