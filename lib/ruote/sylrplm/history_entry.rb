# frozen_string_literal: true

module Ruote
  module Sylrplm
    #
    # The active record for process errors. Not much to say.
    #
    class HistoryEntry < ActiveRecord::Base
      include OpenWFE::Extras::SingleConnectionMixin
      include Models::SylrplmCommon

      attr_reader :link_attributes

      # TODO: syl set_table_name('history')
      # ko rails 4set_table_name('history_entry')
      # ok rails4
      self.table_name = 'history_entry'

      def self.model_name
        'history_entry'
      end

      #
      # returns a FlowExpressionId instance if the entry has a 'fei' or
      # nil instead.
      #
      def full_fei
        fei ? OpenWFE::FlowExpressionId.from_s(fei) : nil
      end

      #
      # Directly logs an event (may throw an exception)
      #
      def self.log!(source, event, opts = {})
        fei = opts[:fei]

        if fei
          opts[:wfid] = fei.parent_wfid
          opts[:wfname] = fei.wfname
          opts[:wfrevision] = fei.wfrevision
          opts[:fei] = fei.to_s
        end

        opts[:source] = source.to_s
        opts[:event] = event.to_s

        # self.new(opts).save!
        # syl: unknown attribute
        opts.delete(:inflow)
        ret = new(opts)
        st = ret.save_without_transactions!
        (st ? ret : nil)
      end

      attr_accessor :link_attributes

      def plm_objects
        fname = "#{self.class.name}.#{__method__}"
        ret = []
        # self.links_plmobjects.each do |lnk|
        cond = "father_plmtype='history_entry' and father_id = '#{id}'"
        lnks = Link.find(:all, conditions: [cond])
        # LOG.debug (fname){"cond=#{cond} #{lnks.count} link trouves"}
        lnks.each do |lnk|
          # LOG.debug (fname){"lnk=#{lnk} father=#{lnk.father.ident} child=#{lnk.child.ident}"}
          ret.push lnk.child unless lnk.child.nil?
        end
        ret
      end

      def link_attributes=(att)
        fname = "#{self.class.name}.#{__method__}"
        @link_attributes = att
        # LOG.debug (fname){"HistoryEntry:link_attributes=#{@link_attributes}"}
        @link_attributes
      end

      def typesobject
        Typesobject.find_by_forobject(model_name).to_a[0]
      end

      def model_name
        self.class.model_name
      end

      def ident
        # fei.to_s+"_"+wfid.to_s+"_"+wf_name.to_s
        [wfid, wf_name].join('_')
      end

      def cancel?
        source == 'expool' && event == 'cancel'
      end
    end
  end
end
