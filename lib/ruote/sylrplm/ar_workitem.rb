require 'openwfe/extras/participants/ar_participants'
require 'models/plm_object'
module Ruote
  module Sylrplm
    class ArWorkitem < OpenWFE::Extras::ArWorkitem
      include Models::PlmObject
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
        "ar_workitem"
      end

      def ident
        fei+"_"+wfid+"_"+expid+"_"+wfname
      end
    end
  end
end
