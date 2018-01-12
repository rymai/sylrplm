# frozen_string_literal: true

module Ruote
  class Workitem
    # include Ruote::Sylrplm

    def ident
      [wfid, fei.expid, wf_name].join('_')
    end

    def label
      [wf_name, wf_revision].join(' ')
    end

    def expid
      fei.expid
    end

    # def wf_revision
    # wf_revision
    # end
    #
    # def wf_name
    # wf_name
    # end
    def error
      ''
    end

    def modelname
      'workitem'
    end

    def get_hash_objects
      objects
    end

    def get_plm_objects
      fname = "Workitem.#{__method__}"
      ret = []
      ret
    end

    def get_wi_links
      fname = "Workitem.#{__method__}"
      ret = []
      ret
    end

    # return associated objects during process
    def objects
      fname = "Workitem.#{__method__}"
      ret = []
      ret
    end
  end
  end
