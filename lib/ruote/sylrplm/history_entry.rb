require 'openwfe/extras/expool/db_history'

module Ruote
  module Sylrplm
    class HistoryEntry < OpenWFE::Extras::HistoryEntry
      #include Models::PlmObject
      include Models::SylrplmCommon

      attr_accessor :link_attributes
      def link_attributes=(att)
        @link_attributes = att
      end

      def link_attributes
        @link_attributes
      end

      def typesobject
        Typesobject.find_by_object(model_name)
      end

      def model_name
        "history_entry"
      end

      def ident
        fei+"_"+wfid+"_"+expid+"_"+wfname
      end

    end
  end

end
