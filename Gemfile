source 'https://rubygems.org'
#sylrplm debut
ruby "2.1.2"
#pour respond_to dans les controlleurs
###gem 'responders', '~> 2.0'
gem 'responders'
#sylrplm fin

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.5'
#heroku: to enable all platform features
gem 'rails_12factor'
#observer remove from core Rails4
gem 'rails-observers'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
gem 'execjs'
gem 'therubyracer'

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 3.1.0'
###gem 'jquery-ui-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
####gem 'turbolinks', '~> 2.2.2'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

#######################sylrplm debut

# connecteur Database
# Use sqlite3 as the database for Active Record
#gem 'sqlite3'
# be careful, don't activate 0.15.1 version : process processing is ko
#gem 'pg' , '~>0.14.1'
gem 'pg'
###gem 'postgres-pr' #, '~> 0.6.3'
#gem 'activerecord-postgresql-adapter', '~> 0.0.1'
#gem 'mysql2'

# Internals
gem 'yajl-ruby', :require => 'yajl'
#gem 'ruote', '~>2.2.0'
#gem 'ruote', git: 'https://github.com/jmettraux/ruote.git'
gem 'ruote'
gem 'ruote-extras'
gem 'ruote-postgres' , :git => "git://github.com/ifad/ruote-postgres.git"
gem 'ruote-kit', :git => 'http://github.com/tosch/ruote-kit.git'

gem 'fog'  #, '~>1.1.2'
#gem 'rufus-verbs', '~>1.0.0'
#gem 'atom-tools' , '~>2.0.5'
#gem 'rufus-scheduler' , '~>2.0.19'
gem 'rufus-verbs'
gem 'atom-tools'
gem 'rufus-scheduler'

# paginate Views of a lot of lines
#gem 'will_paginate', '3.0.7'
gem 'will_paginate'
#sylrplm fin


# 		read and create zip files
#gem 'rubyzip', '1.1.7'
###gem 'rubyzip'

#gem 'string_to_sha1', :git => "git://github.com/sylvani/string_to_sha1.git"
#gem 'string_to_sha1', :path => "/home/syl/trav/rubyonrails/string_to_sha1"
gem 'sylrplm_ext', :git => "git://github.com/sylvani/sylrplm_ext.git"
###gem 'sylrplm_ext', :path => "/home/syl/trav/rubyonrails/sylrplm_ext"

#If you would like to use RJS, you need to include
gem 'prototype-rails', github: 'rails/prototype-rails', branch: '4.2'
gem 'activerecord-session_store'

#pour rails4 et les attr_accessible
gem 'protected_attributes'
#gem 'strong_parameters'

gem 'simple_form', '~> 3.1.0.rc1'

group :norb do
# 		will load compatibility for old rubyzip API.
#gem 'zip-zip'
#gem 'selenium-webdriver'
end

group :staging, :production do
	#gem 'thin'
	#gem 'rack-ssl'
	#gem 'newrelic_rpm' , '3.14.0.305'
	#gem 'newrelic_rpm'
end

group :development do
	gem 'heroku'
	#gem 'heroku' , '3.42.22'
	#gem 'ruby-debug-base19'
	#gem 'ruby-debug-ide19'
	#gem 'ruby-debug193'
	##gem 'bigdecimal', :path => "/usr/share/ruby/gems/gems/bigdecimal-1.2.5"
	gem 'byebug'
	#gem 'ruby-debug-ide'
	#gem 'web_console'
	#gem 'awesome_print'


group :test do
  gem 'capybara'

  #pb selenium=>jar-wrapper=>zip incompatible avec rubyzip!!!
  #gem 'selenium'
  gem 'launchy'
  gem 'rspec'
  gem 'rspec-core'
end
#######################sylrplm fin

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  #gem 'byebug'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  #gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
 # gem 'spring'
end

group :essai do
	gem 'rb-readline'
	gem 'activesupport'
	gem 'bundler'
	gem 'actionpack'
	##gem 'bigdecimal', '1.2.5'
	gem 'bigdecimal'
	gem 'haml'
	gem 'iconv'
	#gem 'nokogiri'  ,'1.6.6.2' #, '~>1.5.4' 1.6.3.1
	#gem 'nokogiri'
	#defaut ruby 2.1.5 gem 'rake' #, '10.3.2'
	#defaut ruby 2.1.5 gem 'rdoc' #, '4.1.1'
	#gem 'mail', '~>2.3.0'
	gem 'mail'
	#defaut ruby 2.1.5 gem 'json', '~>1.5.5'
	gem 'log4r'
	gem 'locale'
	#
	##gem 'psych', '~> 2.0.5'
	#defaut ruby 2.1.5 gem 'psych', '2.0.6'
	gem 'foreman'
	gem 'letter_opener'
	gem 'railroad'
	#gem 'railroady', '1.4.1'
	gem 'railroady'
end



end
