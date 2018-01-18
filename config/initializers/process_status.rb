# frozen_string_literal: true

module Ruote
  class ProcessStatus
    include Ruote::Sylrplm
    def modelname
      'processstatus'
    end

    def id
      wfid
    end
  end
end
