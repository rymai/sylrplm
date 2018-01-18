# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.default_url_options = { host: 'localhost:3000' }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Settings specified here will take precedence over those in config/environment.rb
  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

	# See everything in the log (default is :info)
	#ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
	config.log_level = :error
#FATAL an unhandleable error that results in a program crash
#ERROR a handleable error condition
#WARN  a warning
#INFO  generic (useful) information about system operation
#DEBUG
###config.http_authenticatable_on_xhr = false
###config.navigational_formats = ["*/*", :html, :json, :js]
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true
config.action_mailer.logger = Logger.new(File.join(Rails.root, 'log', 'sylrplm_mail.log'), 'daily')
# SMTP settings
config.action_mailer.smtp_settings = {
    address:"smtp.free.fr", port:25,
    enable_starttls_auto: false,
    authentication:       "plain",
    user_name:            "sylvani",password:             "pa33zp62",
    domain: "sylrplm"
}

  # Show full error reports and disable caching
  # config.action_view.debug_rjs                         = false
  config.action_view.cache_template_loading = false
end
