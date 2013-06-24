source 'https://rubygems.org'

ruby '2.0.0'

gem 'bundler'

gem 'rails', '3.2.13'
gem 'oj'

# Databases
gem 'pg'

# Internals
gem 'ruote', '~> 2.3'
gem 'fog', '~> 1.12'
gem 'rufus-verbs', '~> 1.0'
gem 'atom-tools' , '~> 2.0.5'
gem 'dalli' # Memcache client
gem 'cache_digests' # Russian-doll views caching

# Views
gem 'will_paginate' #, '~> 2.3.16'


gem 'sylrplm_ext', :git => "git://github.com/sylvani/sylrplm_ext.git"
####gem 'sylrplm_ext', :path => "/home/syl/trav/rubyonrails/sylrplm_ext"

group :staging, :production do
  gem 'unicorn'
  gem 'rack-ssl'
  gem 'newrelic_rpm'
  gem 'lograge'
end

group :development, :test do
  gem 'dotenv-rails'
end

group :development do
  gem 'foreman'
  gem 'letter_opener'
  gem 'railroad'
  gem 'railroady'
end
