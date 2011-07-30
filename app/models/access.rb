#require 'lib/models/sylrplm_common'
class Access < ActiveRecord::Base
  include Models::SylrplmCommon

  attr_accessor :controller_and_action
  attr_accessible :controller_and_action, :roles
  
  validates_presence_of :controller, :action, :roles
  validates_uniqueness_of :action, :scope => :controller
  
  def before_create
    set_default_values(true)
  end
    
  def controller_and_action
    "#{controller}.#{action}"
  end
  
  def controller_and_action=(controller_and_action)
    controller_and_action        = controller_and_action.split('.')
    self.controller, self.action = controller_and_action.shift(2) if controller_and_action.size > 1
  end

  def self.find_for_controller(controller)
    self.all(:order=>"controller", :conditions => ["controller like '#{controller}'"]).inject({}) do |memo, access|
      memo[access.action.to_sym] = access.roles
      memo
    end
  end

  #
  # remplissage initial des autorisations
  #
  def self.init
    Controller.get_controllers.each do |controller|
      roles = if %w[AccessesController LoginController RolesController RolesUsersController SequencesController].include?(controller.name)
        # fonctions admin
        "admin & (!designer | !consultant | !valider)"
      else
        if controller.name == "SessionsController"
          # tout le monde peut se deconnecter
          "admin | designer | consultant | valider"
        else
          # les fonctions plm
          if controller.method == "show"
            "admin | designer | valider | consultant"
          else
            "(admin | designer | valider) & !consultant"
          end
        end
      end
      create(:controller_and_action => "#{controller.name}.#{controller.method}", :roles => roles)
    end
  end

  def self.get_conditions(filter)
    ["controller LIKE ? or action LIKE ? or roles LIKE ?", filter, filter, filter] unless filter.gsub!("*","%").nil?
  end

end
