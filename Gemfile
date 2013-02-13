source 'https://rubygems.org'

ruby '1.9.3'

gem 'bundler'
gem 'rake', '0.8.7'

gem 'rails', '2.3.17'
gem 'mail', '2.3.0'
gem 'json', '1.5.5'

# Databases
gem 'pg'
# gem "mysql", "2.8.1"

# Internals
gem 'ruote', '2.2.0'
gem 'fog', '~> 1.1.2'
gem 'rufus-verbs', '1.0.0'
gem 'atom-tools' , '2.0.5'

# Views
gem 'will_paginate' , '~> 2.3.16'

group :staging, :production do
  gem 'thin'
  gem 'rack-ssl'
  gem 'newrelic_rpm'
end

group :development do
  gem 'foreman'
  gem 'letter_opener'
end
