module Classes
	module AppClasses
		# Build a Logger::Formatter subclass.
		class LogFormatter < Logger::Formatter
			# Provide a call() method that returns the formatted message.
			def initialize(*args)
				puts "LogFormatter:args=#{args}"
				@NOLOGS=args[0]
			end

			def call(severity, time, program_name, message)
				unless (@NOLOGS.index{ |x| !program_name.index(x).nil? })
					datetime      = time.strftime("%Y-%m-%d %H:%M")
					#"ERROR"
					if severity == "toto"
						print_message = "!!! #{String(message)} (#{datetime}) !!!"
						border        = "!" * print_message.length
						ret=[border, print_message, border].join("\n") + "\n"
					else
						#print_message =[severity.ljust(5), datetime.to_s, program_name.to_s, message.to_s].join("|")
						print_message =[severity.ljust(5), program_name.to_s, message.to_s].join("|")
						ret= print_message + "\n"
					end
					puts print_message
				end
				ret
			end
		end

		class LOG_SYLRPLM
			def debug(arg=nil)
				$stdout.puts "LOG.debug"
			end

			def info(arg=nil)
				$stdout.puts "LOG.info"
			end

			def warn(arg=nil)
				$stdout.puts "LOG.warn"
			end
		end
	end
end

# pour les fixtures
=begin
module YAML
def YAML.include file_name
require 'erb'
ERB.new(IO.read(file_name)).result
end
def YAML.load_erb file_name
YAML::load(YAML::include(file_name))
end
end
=end