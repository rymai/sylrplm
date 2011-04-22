#require 'openwfe/representations'
require 'ruote/part/local_participant'
require 'ruote/part/block_participant'

#require 'openwfe/participants/participants'

module Ruote
    class WfPart
      include Ruote::LocalParticipant
      def initialize(opts)
        puts self.Class.name+".initialize****************************************"
        echo self.Class.name+".initialize****************************************"
        @opts = opts
      end

      def consume(workitem)
        puts self.Class.name+".consume*********************************************"
        echo self.Class.name+".consume*********************************************"
        #         h = workitem.to_h
        #        h['fei'] = workitem.fei.sid
        #        File.open("worklist/workitem_#{workitem.fei.sid}.yaml", wb) do |f|
        #          f.puts(h.to_yaml)
        #        end
        reply_to_engine(workitem)
      end

      def cancel(fei, flavour)
        #        FileUtils.rm("worklist/workitem_#{fei.sid}.yaml")
      end

      # A method called by external systems when they're done with a workitem
      # hash, they hand it back to the engine via this method.
      #
      def self.reply(workitem_h)
        puts self.Class.name+".reply*********************************************"
        echo self.Class.name+".reply*********************************************"
        #       FileUtils.rm("worklist/workitem_#{workitem_h['fei']}.yaml")
        reply_to_engine(workitem)
      end
    end

end

