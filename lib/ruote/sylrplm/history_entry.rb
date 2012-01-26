require 'openwfe/extras/expool/db_history'

module Ruote
  module Sylrplm
    class HistoryEntry < OpenWFE::Extras::HistoryEntry
      #include Models::PlmObject
      include Models::SylrplmCommon

      has_many :links_documents, :class_name => "Link", :foreign_key => "child_id", :conditions => ["father_plmtype='history_entry' and child_plmtype='document'"]
      has_many :documents , :through => :links_documents

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
        HistoryEntry.model_name
      end

      def self.model_name
        "history_entry"
      end

      def ident
        #fei.to_s+"_"+wfid.to_s+"_"+wfname.to_s
        [wfid, wfname].join("_")
      end

      def cancel?
        source=='expool' && event=='cancel'
      end

    end
  end

end
