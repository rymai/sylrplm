#--
# Copyright (c) 2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

#require_gem 'activerecord'
#gem 'activerecord'; require 'active_record'
require 'active_record'

module Ruote
	module Sylrplm

		#
		# Dumber connection management for records that need to be manipulated outside
		# of the HTTP request circuit (where Rails takes care of everything).
		#
		module SingleConnectionMixin
			def self.included (target_module)

				target_module.module_eval do
					def self.connection_
						fname= "#{self.class.name}.#{__method__}"

						#ActiveRecord::Base.configurations = Rails.application.config.database_configuration
						LOG.debug(fname) {"useActiveRecord::Base.configurations=#{ActiveRecord::Base.configurations[Rails.env]}"}
						#ActiveRecord::ConnectionAdapters::ConnectionPool.new Rails.application.config.database_configuration[Rails.env]
						#
						#ActiveRecord::Base.connection_pool.checkout
						#@@connection ||= ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[Rails.env])
						ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[Rails.env])
						#ActiveRecord::Base.connection
						ActiveRecord::Base.connection.reconnect!
						#LOG.debug(fname) {"@@connection=#{@@connection}"}
						#@@connection
					end

					def self.connection_rail2
						ActiveRecord::Base.verify_active_connections!
						@@connection ||= ActiveRecord::Base.connection_pool.checkout
						#puts "#{__FILE__} : connection active= #{connection.active?}"
						@@connection.active? || @@connection.reconnect!
						@@connection
					end
				end
			end

		end

	end
end
