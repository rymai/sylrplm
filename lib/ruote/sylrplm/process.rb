
# frozen_string_literal: true

module Ruote
  module Sylrplm
    class Process
      def self.get_all
        fname = "Process.#{__method__}"
        v = ::SYLRPLM::RUOTE_ENGINE.processes
        LOG.debug(fname) { "Process: #{v}" }
        vv = []
        v.each do |ps|
          LOG.debug(fname) { "Process: ps=#{ps} launch_time=#{ps.launch_time}" }
          vv << ps unless ps.launch_time.nil?
        end
        all_processes = vv.sort_by(&:launch_time).reverse
        LOG.debug(fname) { "Process: fin all_processes=#{all_processes} " }
        all_processes
      end

      def self.exists_on_object_for_action?(object, _action)
        fname = "Process.#{__method__}"
        all_processes = get_all
        LOG.debug(fname) { "#{all_processes.length} processes" }
        all_processes.each do |ps|
          LOG.debug(fname) { "ps=#{ps.wfid}" }
          workitems = Ruote::Sylrplm::ArWorkitem.find(:all, conditions: ['wfid = ?', ps.wfid.to_s])
          # workitems = Ruote::Sylrplm::ArWorkitem.find_all
          LOG.debug(fname) { "#{workitems.length} workitems}" }
          workitems.each do |work|
            fields = work.field_hash
            # LOG.debug(fname){"fields=#{fields}"}
            url = "/#{object.modelname}s/#{object.id}"
            LOG.debug(fname) { "fields=#{fields} url=#{url} trouve=#{fields['params'][url]}" }
            return true unless fields['params'][url].nil?
          end
        end
        false
      end
    end
  end
end
