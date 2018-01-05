# frozen_string_literal: true

require 'active_record/connection_adapters/abstract_adapter'

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter < AbstractAdapter
      # sylrplm: pour eviter le rechargement des connexions
      def requires_reloading?
        ret = false
        puts "TODO:#{__FILE__}:#{__method__} by syl:#{ret}"
        ret
      end
    end
  end
end
