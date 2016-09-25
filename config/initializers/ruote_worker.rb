module Ruote
	class Worker
      def handle_step_error(e, msg)
      	fname= "#{self.class.name}.#{__method__}"
        logger.error(fname) {'ruote step error: ' + e.inspect}
       # mailer.send_error('admin@acme.com', e)
      end
    end
end