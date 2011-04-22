# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.10' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  config.gem(
      'mislav-will_paginate',
      :version => '~> 2.3.6',
      :lib => 'will_paginate',
      :source => 'http://gems.github.com')
      
  #config.gem 'will_paginate', :version => '~> 2.3.15', :source => 'http://gemcutter.org'

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{Rails.root}/lib/classes )

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  config.action_controller.session_store = :active_record_store

  config.i18n.default_locale = :fr

  config.action_mailer.delivery_method       = :smtp
  config.action_mailer.perform_deliveries    = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_charset       = 'utf-8'

  config.action_mailer.smtp_settings = {
    :address => "smtp.free.fr",
    :port => 25,
    :domain => "free.fr"
    #:authentication => :login,
    #:user_name => xxx,
    #:password => xxx
  }
  
  #RUOTE_ENV = {:persist_as_yaml=>true}
  RUOTE_ENV = {}
    # passing a hash of parameters (application context) to the ruote engine
    # (well via the ruote_plugin)
  
    
  
  $:.unshift('~/ruote/lib')
    # using the local 'ruote', comment that out if you're using ruote as a gem


end

# environneemnt specifique a l'admin de l'application sylrplm
require 'os_functions'
require File.join(File.dirname(__FILE__), 'sylrplm')

if File.exists?(File.join(File.dirname(__FILE__), "sylrplm_#{OsFunctions.os}.rb"))
  require File.join(File.dirname(__FILE__), "sylrplm_#{OsFunctions.os}")
else
  puts "#{File.join(File.dirname(__FILE__), "sylrplm_#{OsFunctions.os}")} doesn't exist!"
end