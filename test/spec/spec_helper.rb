# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'
require File.expand_path(File.dirname(__FILE__) + '/../config/environment')

require 'capybara'
require 'capybara/rails'
require 'capybara/rspec'
require 'yaml'

# Choix du driver par défaut : selenium pour le Javascript
Capybara.default_driver = :selenium
