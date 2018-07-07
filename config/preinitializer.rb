# frozen_string_literal: true

begin
  require 'rubygems'
  require 'bundler'
rescue LoadError
  raise 'Could not load the bundler gem. Install it with `gem install bundler`.'
end

if Gem::Version.new(Bundler::VERSION) <= Gem::Version.new('0.9.24')
  raise 'Your bundler version is too old for Rails 2.3.' \
                      'Run `gem install bundler` to upgrade.'
end

begin
  # Set up load paths for all bundled gems
  ENV['BUNDLE_GEMFILE'] = File.expand_path('../../Gemfile', __FILE__)
  Bundler.setup
rescue Bundler::GemNotFound
  raise "Bundler couldn't find some gems." \
                      'Did you run `bundle install`?'
end
