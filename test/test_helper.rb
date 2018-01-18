# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'
require File.expand_path(File.dirname(__FILE__) + '/../config/environment')

# require File.expand_path(File.dirname(__FILE__) + "/../config/initializers/sylrplm_init")
# require 'test_help'

# require File.dirname(__FILE__) + '/../lib/caboose/logic_parser'
# require File.dirname(__FILE__) + '/../lib/caboose/role_handler'
# require File.dirname(__FILE__) + '/../lib/caboose/access_control'
require 'rails/test_help'
# Choix du driver par défaut : selenium pour le Javascript
Capybara.default_driver = :selenium

# class ActionDispatch::IntegrationTest
# Intégration de Capybara dans tout les tests d'intégration.
# include Capybara::DSL
# end
class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!
  # fixtures :all
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.

  # SYL TODO error self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.

  # syl TODO error self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # syl TODO fixtures :all
  # Add more helper methods to be used by all tests here...
  def login_as_admin(request)
    u = users(:user_admin)
    puts "test_helper.login_as_admin:#{u.inspect}"
    @current_user = u
    request.session[:user_id] = u.id
  end

  def save_volumes
    Volume.find_all.each(&:save)
  end
end

class CapybaraTestCase < ActiveSupport::TestCase
  # SYL TODOinclude Capybara::DSL
  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
