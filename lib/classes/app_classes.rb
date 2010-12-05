module AppClasses
  # Build a Logger::Formatter subclass.
  class LogFormatter < Logger::Formatter
    # Provide a call() method that returns the formatted message.
    def call(severity, time, program_name, message)
      datetime      = time.strftime("%Y-%m-%d %H:%M")
      if severity == "ERROR"
        
        print_message = "!!! #{String(message)} (#{datetime}) !!!"
        border        = "!" * print_message.length
        [border, print_message, border].join("\n") + "\n"
      else
        #super
        [severity.ljust(5), datetime, program_name, message].join("_") + "\n"
      end
    end
  end
end

