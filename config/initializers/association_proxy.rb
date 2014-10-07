#Ruby 2.0 is no longer returns true from respond_to? for protected methods. That's why it's failing in for rails 3.0 on ruby 2.0.
#AssociationProxy redefines send method.

#if Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 0 && RUBY_VERSION >= "2.0.0"
if Rails::VERSION::MAJOR == 2 && Rails::VERSION::MINOR == 3 && RUBY_VERSION >= "2.0.0"
	module ActiveRecord
		module Associations
			class AssociationProxy
				def send(method, *args)
					if proxy_respond_to?(method, true)
					super
					else
						load_target
					@target.send(method, *args)
					end
				end

				#Because autosave_association.rb:334 was not triggered:
				#association.send(:construct_sql) if association.respond_to?(:construct_sql)
				def respond_to?(symbol, include_private=false)
					super(symbol, true)
				end

			end
		end
	end
end

