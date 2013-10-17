require_dependency 'models/sylrplm_common'

class Access < ActiveRecord::Base
  include Models::SylrplmCommon

  attr_accessor :controller_and_action

  attr_accessible :controller_and_action, :roles, :id, :controller, :action

  validates_presence_of :controller, :action, :roles
  validates_uniqueness_of :action, :scope => :controller

  def controller_and_action
    "#{controller}.#{action}"
  end

  def controller_and_action=(controller_and_action)
    controller_and_action        = controller_and_action.split('.')
    self.controller, self.action = controller_and_action.shift(2) if controller_and_action.size > 1
  end

  def self.find_for_controller(controller)
    self.all(order: "controller", conditions: ["controller like '#{controller}'"]).inject({}) do |memo, access|
      memo[access.action.to_sym] = access.roles
      memo
    end
  end

  def self.reset
    #delete et remplissage des autorisations
    delete_all
    init
  end

  def self.get_conditions(filter)
    filter = filter.gsub("*", "%")
    ret = {}
    unless filter.nil?
      ret[:qry] = " controller LIKE :v_filter or action LIKE :v_filter or roles LIKE :v_filter "
      ret[:values] = { :v_filter => filter }
    end
    ret
  end

  def ident
    "#{controller}.#{action}"
  end

  private

  #
  # liste des roles par categories utilisables par access
  # - admins:
  # - consultants
  # - modifier
  #
  def self.access_roles
    ret = { :cat_admins => [], :cat_consultants => [], :cat_creators => [] }
    admin = Role.find_by_name(PlmServices.get_property(:ROLE_ADMIN))
    consultant = Role.find_by_name(PlmServices.get_property(:ROLE_CONSULTANT))
    ret[:cat_admins] << admin.title unless admin.nil?
    #ret[:cat_consultants] = cons.users.collect{ |u| u.login } unless cons.nil?
    ret[:cat_consultants] << consultant.title unless consultant.nil?
    #puts "#{__method__.to_s}:cat_admins=#{ret[:cat_admins]}"
    #puts "#{__method__.to_s}:cat_consultants=#{ret[:cat_consultants]}"
    ret[:cat_creators] = Role.all.collect { |r| r.title } 
    #puts "#{__method__.to_s}:roles=#{ret[:cat_creators]}"
    ret[:cat_creators]-= ret[:cat_admins]
    ret[:cat_creators]-= ret[:cat_consultants]
    #puts "#{__method__.to_s}:#{ret.inspect}"
    ret
  end

  def self.roles_yes(lst)
    roles_prefixe(lst, "")
  end

  def self.roles_no(lst)
    roles_prefixe(lst, "!")
  end

  #ecrit !_role pour chaque role
  def self.roles_prefixe(lst, yes_no)
    lst.inject([]) do |memo, r|
      memo << r unless r.nil?
      memo
    end.join(' | ')
  end
  
  #ecrit !_role pour chaque role
  def self.roles_prefixe(lst, yes_no)
    ret=""
    lst.each_with_index do |r, i|
      ret << " | " unless i == 0
      ret << yes_no + r unless r.nil?
    end
    ret
  end
  
  def self.roles_prefixe_remy(lst, yes_no)
    lst.inject([]) do |memo, r|
      memo << r unless r.nil?
      memo
    end.join(' | ')
  end
  
  #
  # remplissage initial des autorisations
  #
  def self.init
    puts "acces.init:remplissage initial des autorisations"
    acc_roles = Access.access_roles
    Controller.get_controllers_and_methods.each do |controller|
      if %w[AccessesController LoginController RolesController RolesUsersController SequencesController].include?(controller.name)
        #puts "acces.init: fonctions admin"
        roles = roles_yes(acc_roles[:cat_admins]) +"& ("+ roles_no(acc_roles[:cat_consultants]) +"!"+ roles_no(acc_roles[:cat_creators])+ ")"
      #roles = "admin & (!designer | !consultant | !valider)"
      else
        if controller.name == "SessionsController"
          #puts "acces.init: tout le monde peut se deconnecter"
          #roles = "admin | designer | consultant | valider"
          roles = roles_yes(acc_roles[:cat_admins]) +" | "+ roles_yes(acc_roles[:cat_creators]) +" | "+ roles_yes(acc_roles[:cat_consultants])
        elsif controller.name == "WorkitemsController"
          #puts "acces.init: tout le monde peut executer une tache sauf le consultant"
          #roles = "(admin | designer | valider) & !consultant"
          roles = "("+roles_yes(acc_roles[:cat_admins]) +" | "+ roles_yes(acc_roles[:cat_creators]) +") & ("+ roles_no(acc_roles[:cat_consultants])+ ")"
        elsif controller.name == "QuestionsController"
          #puts "acces.init: tout le monde peut poser une question, le consultant ne peut repondre"
          roles=nil
          if controller.method == "edit"
            #roles = "(admin | designer | valider) & !consultant"
            roles = "("+roles_yes(acc_roles[:cat_admins]) +" | "+ roles_yes(acc_roles[:cat_creators]) +") & ("+ roles_no(acc_roles[:cat_consultants])+ ")"
          end
        elsif controller.name == "UsersController"
          #puts "acces.init: seulement admin"
          roles=nil
          if controller.method != "show" && controller.method[0,7] != "account"
            #roles = "(admin | designer | valider) & !consultant"
            roles = roles_yes(acc_roles[:cat_admins])
          end
        else
        # les fonctions plm
          if controller.method == "show"
            #puts "acces.init: fonctions plm:show"
            #roles = "admin | designer | valider | consultant"
            roles = roles_yes(acc_roles[:cat_admins]) +" | "+ roles_yes(acc_roles[:cat_creators]) +" | "+ roles_yes(acc_roles[:cat_consultants])
            roles=nil
          else
          #puts "acces.init: fonctions plm:autres:#{controller.method}"
          #roles = "(admin | designer | valider) & !consultant"
            roles = "("+roles_yes(acc_roles[:cat_admins]) +" | "+ roles_yes(acc_roles[:cat_creators]) +") & ("+ roles_no(acc_roles[:cat_consultants])+ ")"
          end
        end
      end
      create(:controller_and_action => "#{controller.name}.#{controller.method}", :roles => roles) unless roles.nil?
    end
  end

end
