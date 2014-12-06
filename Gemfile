source 'https://rubygems.org'

#dispo sur bundle 1.2
#ruby '1.9.3'
#ruby '2.0.0'
ruby "2.1.5"

#defaut ruby 2.1.5 gem 'test-unit'

gem 'activesupport'

gem 'bundler'

##gem 'bigdecimal', '1.2.1'
##gem 'bigdecimal'

gem 'haml'
gem 'iconv'
gem 'nokogiri'  #, '~>1.5.4' 1.6.3.1

gem 'rails', '2.3.17'
#defaut ruby 2.1.5 gem 'rake' #, '10.3.2'
#defaut ruby 2.1.5 gem 'rdoc' #, '4.1.1'
gem 'mail', '~>2.3.0'
#defaut ruby 2.1.5 gem 'json', '~>1.5.5'
gem 'log4r'
gem 'locale'

# connecteur Database
# be careful, don't activate 0.15.1 version : process processing is ko
gem 'pg' , '~>0.14.1'
###gem 'postgres-pr' #, '~> 0.6.3'
#gem 'activerecord-postgresql-adapter', '~> 0.0.1'
#gem 'mysql2'


# Internals
gem 'ruote', '~>2.2.0'
#gem 'ruote-extras'
##### ko gem 'ruote-postgres' , :git => "git://github.com/ifad/ruote-postgres.git"

gem 'fog'  #, '~>1.1.2'
gem 'rufus-verbs', '~>1.0.0'
gem 'atom-tools' , '~>2.0.5'
gem 'rufus-scheduler' , '~>2.0.19'
gem 'capybara'

# paginate Views of a lot of lines
gem 'will_paginate' , '~> 2.3.16'

#gem 'before_render'

#
##gem 'psych', '~> 2.0.5'

#defaut ruby 2.1.5 gem 'psych', '2.0.6'

# read and create zip files
gem 'zip-zip'

#gem 'string_to_sha1', :git => "git://github.com/sylvani/string_to_sha1.git"
#gem 'string_to_sha1', :path => "/home/syl/trav/rubyonrails/string_to_sha1"

gem 'sylrplm_ext', :git => "git://github.com/sylvani/sylrplm_ext.git"
###gem 'sylrplm_ext', :path => "/home/syl/trav/rubyonrails/sylrplm_ext"

gem 'foreman'
	gem 'letter_opener'
	gem 'railroad'
	gem 'railroady'

group :staging, :production do
	gem 'thin'
	gem 'rack-ssl'
	gem 'newrelic_rpm'
	##gem 'bigdecimal'
end

group :development do
	#gem 'ruby-debug-base19'
	#gem 'ruby-debug-ide19'
	#gem 'ruby-debug193'
	##gem 'bigdecimal', :path => "/usr/share/ruby/gems/gems/bigdecimal-1.2.5"
	gem 'ruby_debugger'

end
