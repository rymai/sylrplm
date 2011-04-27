module Ruote
  class SylArWorkitem < OpenWFE::Extras::ArWorkitem
    attr_accessor :link_attributes
    def initialize(att)
      @link_attributes = att
    end

    def link_attributes=(att)
      @link_attributes = att
    end
  end
end