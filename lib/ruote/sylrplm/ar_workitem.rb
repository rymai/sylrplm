# frozen_string_literal: true

# require 'openwfe/extras/participants/ar_participants'

module Ruote
  module Sylrplm
    include Models::PlmObject
    include Models::SylrplmCommon
    # class ArWorkitem < OpenWFE::Extras::ArWorkitem
    class ArWorkitem < ActiveRecord::Base
      include Models::PlmObject
      include Models::SylrplmCommon
      attr_accessor :link_attributes, :tree, :error, :user
      attr_accessible :wfid, :expid, :wf_name, :wf_revision, :participant_name, :fields, :event
      attr_accessible :owner_id, :projowner_id
      belongs_to :owner, class_name: 'User'
      belongs_to :projowner, class_name: 'Project'

      SEP_TYPE_ITEM = ':'
      SEP_URL = '/'
      def get_hash_objects
        objects
  end

      def to_s
        ident
  end

      attr_writer :link_attributes

      attr_reader :link_attributes

      def typesobject
        #::Typesobject.find_by_forobject(modelname).to_a[0]
        ::Typesobject.find_by_forobject(modelname)
      end

      def modelname
        'ar_workitem'
      end

      def ident
        # fei+"_"+wfid+"_"+expid+"_"+wf_name
        [wfid, expid, wf_name].join('_')
      end

      def label
        [wf_name, wf_revision].join(' ')
      end

      def initialize_(*args)
        fname = "ArWorkitem.#{__method__}"
        LOG.debug(fname) { (args[0]).to_s }
        workitem = args[0]
      end

      def self.create_from_wi(i_workitem, i_user)
        fname = "ArWorkitem.#{__method__}"
        LOG.debug(fname) { "i_workitem=#{i_workitem.inspect}" }
        LOG.debug(fname) { "i_workitem.fields=#{i_workitem.fields}" }
        LOG.debug(fname) { "i_user=#{i_user.inspect}" }
        params = build_params(i_workitem, i_user)
        ar_workitem = Ruote::Sylrplm::ArWorkitem.new(params)
        ar_workitem.fields = i_workitem.fields
        ar_workitem.save
        LOG.debug(fname) { "ar_workitem=#{ar_workitem.inspect}" }
        LOG.debug(fname) { "ar_workitem.fields=#{ar_workitem.fields}" }
        ar_workitem
      end

      def self.update_from_wi(ar_workitem, i_workitem, i_user)
        fname = "ArWorkitem.#{__method__}"
        LOG.debug(fname) { "i_workitem=#{i_workitem.inspect}" }
        LOG.debug(fname) { "i_workitem.fields=#{i_workitem.fields}" }
        LOG.debug(fname) { "i_user=#{i_user.inspect}" }
        params = build_params(i_workitem, i_user)
        ar_workitem.update_attributes(params)
        LOG.debug(fname) { "ar_workitem.fields avant merge=#{ar_workitem.fields}" }
        if ar_workitem.fields.nil?
          ar_workitem.fields = i_workitem.fields
        else
          fields = eval(ar_workitem.fields)
          LOG.debug(fname) { "fields avant merge=#{fields}" }
          unless ar_workitem.fields['params']
            ar_workitem.fields['params'] = fields['params'].merge(i_workitem.fields['params'])
          end
        end
        ar_workitem.save
        LOG.debug(fname) { "ar_workitem=#{ar_workitem.inspect}" }
        LOG.debug(fname) { "ar_workitem.fields=#{ar_workitem.fields}" }
        ar_workitem
      end

      def self.build_params(i_workitem, _i_user)
        params = {}
        params[:wfid] = i_workitem.wfid
        # params[:sid]=i_workitem.sid
        params[:expid] = i_workitem.fei.expid
        params[:wf_name] = i_workitem.wf_name
        params[:wf_revision] = i_workitem.wf_revision
        params[:participant_name] = i_workitem.participant_name
        # params[:store_name]=i_workitem.store_name
        # params[:activity]=i_workitem.activity
        # params[:keywords]=i_workitem.keywords

        # params[:launched_at]=i_workitem.launched_at
        # params[:dispatched_at]=i_workitem.dispatched_at
        # params[:owner_id]=i_user.id
        # params[:projowner_id]=i_user.project_id
        params
      end

      def cancel?
        histo = Ruote::Sylrplm::ArWorkitem.find_by_wfid_and_source_and_event(wfid, 'expool', 'cancel')
        !histo.nil?
      end

      # delete of workitems of a process
      def self.destroy_process(wfid)
        fname = "ArWorkitem.#{__method__}"
        LOG.info(fname) { "wfid=#{wfid}" }
        find_by_wfid_(wfid).each do |ar|
          LOG.info(fname) { "workitem to destroy=#{ar}" }
          ar.destroy
        end
      end

      def before_destroy
        fname = 'ArWorkitem.' + __method__.to_s + ':'
        links = Link.find_childs(self)
        LOG.info(fname) { "#{(links.nil? ? '0' : links.count.to_s)} liens a detruire" }
        links.each(&:destroy)
      end

      def get_wi_links
        fname = "ArWorkitem.#{__method__}"
        ret = []
        history = Ruote::Sylrplm::ArWorkitem.find_by_wfid_and_event(wfid, 'proceeded')
        unless history.nil?
          %w[document part project customer user].each do |typeplm|
            mdl = eval typeplm.capitalize
            Link.find_childs(history, typeplm).each do |link|
              begin
                ret << { typeobj: mdl.find(link.child_id), link: link }
              rescue Exception => e
                LOG.warn(fname) { "Error: #{e}" }
              end
            end
          end
        end
        LOG.debug(fname) { "id=#{id}, size=#{ret.size}:#{ret.inspect}" }
        ret
      end

      def get_wi_links_old
        fname = "ArWorkitem.#{__method__}"
        ret = []
        history = Ruote::Sylrplm::ArWorkitem.find_by_wfid_and_event(wfid, 'proceeded')
        unless history.nil?
          Link.find_childs(history, 'document').each do |link|
            ret << { typeobj: Document.find(link.child_id), link: link }
          end
          Link.find_childs(history, 'part').each do |link|
            ret << { typeobj: Part.find(link.child_id), link: link }
          end
          Link.find_childs(history, 'project').each do |link|
            ret << { typeobj: Product.find(link.child_id), link: link }
          end
          Link.find_childs(history, 'customer').each do |link|
            ret << { typeobj: Customer.find(link.child_id), link: link }
          end
          Link.find_childs(history, 'user').each do |link|
            ret << { typeobj: User.find(link.child_id), link: link }
          end
        end
        LOG.debug(fname) { "id=#{id}, size=#{ret.size}:#{ret.inspect}" }
        ret
      end

      def get_plm_objects
        fname = "ArWorkitem.#{__method__}"
        hash_objects = objects
        ret = []
        # LOG.debug(fname) {"hash_objects=#{hash_objects} obj=#{hash_objects[:obj]} "}
        hash_objects[:obj].each do |key|
          tab = key.split(SEP_URL)
          # LOG.debug(fname) {"tab=#{tab.size} mdl=#{tab[1]}  id=#{tab[2]} "}
          # TODO remplacer chop par une fonction de service
          if tab.size == 3
            plmobj = PlmServices.get_object(tab[1].chop, tab[2])
            ret << plmobj
          end
        end
        LOG.debug(fname) { "ret=#{ret.inspect}" }
        ret
      end

      # return associated objects during process
      def objects
        fname = "ArWorkitem.#{__method__}"
        LOG.debug(fname) { "self.fields=#{fields}" }
        params = eval(fields)['params'] unless fields.nil?
        ret = []
        ret = { obj: params.keys } unless params.nil?
        LOG.debug(fname) { "self.fields=#{fields} params=#{params} ret=#{ret}" }
        ret
      end

      def self.get_workitem(wfid)
        fname = "ArWorkitem.#{__method__}"
        LOG.debug(fname) { "wfid=#{wfid}" }
        # require 'pg'
        # show_activity
        ret = where("wfid = '#{wfid}'")
        LOG.debug(fname) { "ret=#{ret}" }
        ret
      end

      # add an object in fields
      def add_object(object)
        fname = "ArWorkitem.#{__method__}"
        ret = 0
        type_object = object.model_name
        fields = eval self.fields
        if fields.nil?
          fields = {}
          fields['params'] = {}
        end
        url = "#{SEP_URL}#{type_object}s"
        url += "#{SEP_URL}#{object.id}"
        label = type_object + SEP_TYPE_ITEM + object.ident
        if fields['params'][url] == label
          LOG.info(fname) { 'Objet deja present dans cette tache' }
        else
          LOG.info(fname) { "fields[params]=#{fields['params']}" }
          LOG.info(fname) { "url=#{url}" }
          fields['params'][url] = label
          ret += 1
          replace_fields(fields)
        end
        ret
      end

      def show_activity
        # Output a table of current connections to the DB
        conn = PG.connect(dbname: 'sylrplm_development', user: 'postgres', password: 'pa33zp62')
        conn.exec('SELECT * FROM pg_stat_activity') do |result|
          puts '     PID | User             | Query'
          result.each do |row|
            puts format(' %7d | %-16s | %s ', row.values_at('pid', 'usename', 'query'))
          end
        end
      end
    end
  end
end
