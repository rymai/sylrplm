# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
#RAILS_GEM_VERSION = '2.3.12' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# monkey patch for 2.0. Will ignore vendor gems.
if RUBY_VERSION >= "2.0.0"
	module Gem
		def self.source_index
			sources
		end

		def self.cache
			sources
		end

		SourceIndex = Specification

		class SourceList
		      # If you want vendor gems, this is where to start writing code.
		      def search( *args ); []; end
		      def each( &block ); end
		      include Enumerable
		end
	end
end

Rails::Initializer.run do |config|

	#config.gem 'haml'
  # etc
  # maybe some more
  # and so on...

  # Note that iconv is a gem in ruby-2.0
  #config.gem 'iconv' if RUBY_VERSION >= "2.0.0"

# Settings in config/environments/* take precedence over those specified here.
# Application configuration should go into files in config/initializers
# -- all .rb files in that directory are automatically loaded.

  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8

	# config.gem 'will_paginate', :version => '~> 2.3.15', :source => 'http://gemcutter.org'
	# Add additional load paths for your own custom dirs

	config.autoload_paths += %W[#{Rails.root}/lib/classes #{Rails.root}/app/helpers]
	config.autoload_paths += %W[#{Rails.root}/lib/controllers]
	config.autoload_paths += %W[#{Rails.root}/lib/helper]
	config.autoload_paths += %W[#{Rails.root}/lib/models]
	config.autoload_paths += %W[#{Rails.root}/lib/ruote/sylrplm]
	
	# Only load the plugins named here, in the order given (default is alphabetical).
	# :all can be used as a placeholder for all plugins not explicitly named
	# config.plugins = [ :exception_notification, :ssl_requirement, :all ]

	# Skip frameworks you're not going to use. To use Rails without a database,
	# you must remove the Active Record framework.
	# config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

	# Activate observers that should always be running
	# config.active_record.observers = :cacher, :garbage_collector, :forum_observer
	#config.active_record.observers = :document_observer, :part_observer, :project_observer, :customer_observer
	config.active_record.observers = :plmobserver

	# Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
	# Run "rake -D time" for a list of tasks for finding time zone names.
	config.time_zone = 'UTC'

	# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
	config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
  
  #I18n.enforce_available_locales will default to true in the future
  config.i18n.enforce_available_locales = false
	
	# config.i18n.default_locale = :de
	config.i18n.default_locale = :fr

	config.action_controller.session_store = :active_record_store

	config.action_mailer.delivery_method       = :smtp
	config.action_mailer.perform_deliveries    = true
	config.action_mailer.raise_delivery_errors = true
	config.action_mailer.default_charset       = 'utf-8'

	##RUOTE_ENV = {:persist_as_yaml => false}
	RUOTE_ENV = {}
	# passing a hash of parameters (application context) to the ruote engine
	# (well via the ruote_plugin)

	$:.unshift('~/ruote/lib')
# using the local 'ruote', comment that out if you're using ruote as a gem

end
