module Classes::AppClasses
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
        [severity.ljust(5), "date:"+datetime.to_s, "prg:"+program_name.to_s, "msg:"+message.to_s].join("_") + "\n"
      end
    end
  end
end

module YAML
    def YAML.include file_name
      require 'erb'
      ERB.new(IO.read(file_name)).result
    end
    def YAML.load_erb file_name
      YAML::load(YAML::include(file_name))
    end  
end
