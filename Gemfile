# frozen_string_literal: true

source 'https://rubygems.org'
# sylrplm debut
ruby '2.3.6'

# pour respond_to dans les controlleurs
gem 'responders', '2.3.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails' #, '4.2.5'
# heroku: to enable all platform features
gem 'rails_12factor', '0.0.3'
# observer remove from core Rails4
gem 'rails-observers', '0.1.2'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'

# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'execjs', '2.7.0'
gem 'therubyracer', '0.12.2'

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 3.1.0'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks', '~> 2.2.2'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
gem 'unicorn', '5.2.0'

# for tests
gem 'minitest'

# ######################sylrplm debut

gem 'pg', '0.19.0'

# Internals
gem 'atom-tools', '2.0.5'
gem 'fog', '1.38.0'
gem 'rufus-scheduler', '2.0.24'
gem 'rufus-verbs', '1.0.1'
gem 'ruote', '2.3.0.3'
gem 'ruote-extras', '0.9.18'
gem 'ruote-kit', git: 'https://github.com/tosch/ruote-kit.git'
gem 'ruote-postgres', git: 'https://github.com/ifad/ruote-postgres.git'
# Faster JSON parsing
gem 'yajl-ruby', '1.3.1', require: 'yajl'
gem 'yaml_db', '0.4.2'
# paginate Views of a lot of lines
gem 'will_paginate', '3.1.5'

# read and create zip files
gem 'rubyzip', '1.1.7'
gem 'zip-zip'

gem 'sylrplm_ext', :git => "https://github.com/sylvani/sylrplm_ext.git"
# gem 'sylrplm_ext', :path => "/home/syl/trav/rubyonrails/sylrplm_ext"

#If you would like to use RJS, you need to include
gem 'activerecord-session_store','1.0.0'
gem 'prototype-rails', git: 'https://github.com/rails/prototype-rails.git', branch: '4.2'

# pour rails4 et les attr_accessible
gem 'protected_attributes', '1.1.3'
# gem 'strong_parameters'

gem 'simple_form', '~> 3.1.0.rc1'

# detect mobile
gem 'useragent', '0.16.8'

gem 'letter_opener_web'
gem "binding_of_caller"
# pour console
gem "rb-readline"
group :production do
  gem 'scout_apm'
  gem 'lograge'
  # gem 'thin'
  # gem 'rack-ssl'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  # gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'

	gem 'byebug', '9.0.6'

	# Better errors handler
  gem 'better_errors', '~> 2.1.0'
end

group :test do
  gem 'capybara', '2.10.1'

  # pb selenium=>jar-wrapper=>zip incompatible avec rubyzip!!!
  # gem 'selenium'
  gem 'launchy', '2.4.3'
  gem 'rspec', '3.5.0'
  gem 'rspec-core', '3.5.4'
end
# ######################sylrplm fin

group :development, :test do
  gem 'dotenv-rails'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug'
  gem 'rubocop', '~> 0.52.1', require: false
end
