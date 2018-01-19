# frozen_string_literal: true

require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env)

module Sylrplm
  class Application < Rails::Application
    # ne sert a rien a priori, raw marche sans
    # ##ActiveSupport.escape_html_entities_in_json = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # config.gem 'haml'
    # etc
    # maybe some more
    # and so on...

    # Note that iconv is a gem in ruby-2.0
    # config.gem 'iconv' if RUBY_VERSION >= "2.0.0"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    Encoding.default_external = Encoding::UTF_8
    Encoding.default_internal = Encoding::UTF_8

    # Add additional load paths for your own custom dirs
    config.autoload_paths.push(*%W[
      #{config.root}/lib/active_record
      #{config.root}/lib/classes
      #{config.root}/lib/controllers
      #{config.root}/lib/helper
      #{config.root}/lib
      #{config.root}/lib/models
      #{config.root}/lib/ruote
      #{config.root}/lib/ruote/sylrplm
      #{config.root}/vendor/plugins/ruote_plugin/lib
      #{config.root}/vendor/plugins/acl_system2/lib
    ])

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Skip frameworks you're not going to use. To use Rails without a database,
    # you must remove the Active Record framework.
    # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
    # config.active_record.observers = :document_observer, :part_observer, :project_observer, :customer_observer
    # TODO syl ko rails 4
    config.active_record.observers = :plmobserver

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names.
    config.time_zone = 'UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    # I18n.enforce_available_locales will default to true in the future
    config.i18n.enforce_available_locales = false

    # config.i18n.default_locale = :de
    config.i18n.default_locale = :fr

    config.action_mailer.delivery_method = ENV['MAILER_DELIVERY_METHOD'].to_sym
    config.action_mailer.default_url_options = { host: ENV['HOSTNAME'] }

    # dans session_store config.action_controller.session_store = :active_record_store

    # #RUOTE_ENV = {:persist_as_yaml => false}
    RUOTE_ENV = {}.freeze
    # passing a hash of parameters (application context) to the ruote engine
    # (well via the ruote_plugin)

    $LOAD_PATH.unshift('~/ruote/lib') if Rails.env.development?
    # using the local 'ruote', comment that out if you're using ruote as a gem

    # config.http_authenticatable_on_xhr = false
    # config.navigational_formats = ["*/*", :html, :json]
  end
end
