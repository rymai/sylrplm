source 'https://rubygems.org'

#dispo sur bundle 1.2
ruby '1.9.3'

gem 'bundler'

gem 'rails', '2.3.17'

gem 'mail', '2.3.0'
gem 'json', '1.5.5'

# connecteur Database
# be careful, don't activate 0.15.1 version : process processing is ko
gem 'pg', '0.14.1'

# Internals
gem 'ruote', '2.2.0'
#gem 'ruote-extras'
#gem 'ruote-postgres'
gem 'fog', '~> 1.1.2'
gem 'rufus-verbs', '1.0.0'
gem 'atom-tools' , '2.0.5'
gem 'rufus-scheduler' , '2.0.19'
gem 'capybara'

# Views
gem 'will_paginate' , '~> 2.3.16'

#gem 'before_render'

###gem 'sylrplm_ext', :git => "git://github.com/sylvani/sylrplm_ext.git"
####gem 'sylrplm_ext', :path => "/home/syl/trav/rubyonrails/sylrplm_ext"

###gem 'psych'
gem 'psych', '~> 2.0.5'

gem 'zip-zip'

group :staging, :production do
  gem 'thin'
  gem 'rack-ssl'
  gem 'newrelic_rpm'
end

group :development do
	#gem 'ruby-debug-base19'
	#gem 'ruby-debug-ide19'
	#gem 'ruby-debug193'
	gem 'ruby_debugger'
  gem 'foreman'
  gem 'letter_opener'
  gem 'railroad'
	gem 'railroady'
end
