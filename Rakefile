# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake/dsl_definition'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

module ::sylrplm  
  class Application
    include Rake::DSL
  end
end
