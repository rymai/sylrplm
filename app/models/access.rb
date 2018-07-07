# frozen_string_literal: true

require_dependency 'models/sylrplm_common'
require_dependency 'acl_system2/lib/caboose/access_control'
require_dependency 'acl_system2/lib/caboose/role_handler'
require_dependency 'acl_system2/lib/caboose/logic_parser'

class Access < ActiveRecord::Base
  include ::Models::SylrplmCommon
  include ::Caboose
  include ::Caboose::AccessControl

  before_save :before_save_
  before_destroy :before_destroy_
  attr_accessor :controller_and_action

  attr_accessible :id, :roles, :controller, :action, :domain

  validates_presence_of :controller, :action, :roles
  validates_uniqueness_of :action, scope: :controller

  def controller_and_action
    "#{controller}.#{action}"
  end

  def controller_and_action=(controller_and_action)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "controller_and_action=#{controller_and_action}" }
    controller_and_action        = controller_and_action.split('.')
    self.controller, self.action = controller_and_action.shift(2) if controller_and_action.size > 1
  end

  def self.prepare(params)
    fname = "#{self.class.name}.#{__method__}"
    ret = {}
    controller_action = params[:controller_and_action].split('.')
    controller, action = controller_action.shift(2) if controller_action.size > 1
    ret[:controller] = controller
    ret[:action] = action
    ret[:roles] = params[:roles]
    ret
  end

  def self.find_for_controller(controller)
    # rails2 self.all(order: "controller", conditions: ["controller like '#{controller}'"]).inject({}) do |memo, access|
    all.order('controller').where("controller like '#{controller}'").each_with_object({}) do |access, memo|
      memo[access.action.to_sym] = access.roles
    end
  end

  def self.get_actions_by_roles
    fname = "#{self.class.name}.#{__method__}"
    access_actions = Access.all.order('controller, roles, action')
    LOG.debug(fname) { "begin list access_actions:#{access_actions.size}" }
    controllers_actions = {}
    access_actions.each do |aa|
      controllers_actions[aa.controller] = {} if controllers_actions[aa.controller].nil?
      controllers_actions[aa.controller][aa.action] = aa.roles
    end
    actions_by_roles = {}
    user = User.find_by_name(PlmServices.get_property(:USER_ADMIN))
    roles = ::Role.all.order('title').to_a
    roles.each do |arole|
      actions_by_roles[arole] = {}
      user.role = arole
      access_actions.each do |aa|
        c = (eval aa.controller).new
        access_context = { user: user }
        actions = controllers_actions[aa.controller]
        st = allowed?(actions, aa.action, access_context)
        actions_by_roles[arole][aa.controller] = [] if actions_by_roles[arole][aa.controller].nil?
        actions_by_roles[arole][aa.controller] << aa.action if st == true
      end
    end
    # traces
    actions_by_roles.each_key do |role|
      actions_by_roles[role].each do |controller|
        unless controller[1].nil?
          next unless controller[1].count > 0
          LOG.debug(fname) { "controller=#{controller[0]} , #{controller[1].count} actions=#{controller[1]}" }
        end
      end
    end
    actions_by_roles
  end

  def self.allowed?(actions, action, access_context)
    if actions.key? action
      ret = RoleHandler.new.process(actions[action].dup, access_context)
      ret
    elsif actions.key? :DEFAULT
      ret = RoleHandler.new.process(actions[:DEFAULT].dup, access_context)
      ret
    else
       true
    end
      end

  def self.reset
    # delete et remplissage des autorisations
    delete_all
    init
  end

  def self.get_conditions(filter)
    filter = filter.tr('*', '%')
    ret = {}
    unless filter.nil?
      ret[:qry] = " controller LIKE :v_filter or action LIKE :v_filter or roles LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
      ret[:values] = { v_filter: filter }
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
  # - creator
  #
  def self.access_roles
    ret = { cat_admins: [], cat_consultants: [], cat_creators: [] }
    admin = Role.find_by_name(PlmServices.get_property(:ROLE_ADMIN))
    consultant = Role.find_by_name(PlmServices.get_property(:ROLE_CONSULTANT))
    ret[:cat_admins] << admin.title unless admin.nil?
    ret[:cat_consultants] << consultant.title unless consultant.nil?
    ret[:cat_creators] = Role.all.collect(&:title)
    ret[:cat_creators] -= ret[:cat_admins]
    ret[:cat_creators] -= ret[:cat_consultants]
    ret
  end

  def self.roles_yes(lst)
    roles_prefixe(lst, '')
  end

  def self.roles_no(lst)
    roles_prefixe(lst, '!')
  end

  # ecrit !_role pour chaque role
  def self.roles_prefixe(lst, _yes_no)
    lst.each_with_object([]) do |r, memo|
      memo << r unless r.nil?
    end.join(' | ')
  end

  # ecrit !_role pour chaque role
  def self.roles_prefixe(lst, yes_no)
    ret = ''
    lst.each_with_index do |r, i|
      ret +=' | ' unless i == 0
      ret += yes_no + r unless r.nil?
    end
    ret
  end

  def self.roles_prefixe_remy(lst, _yes_no)
    lst.each_with_object([]) do |r, memo|
      memo << r unless r.nil?
    end.join(' | ')
  end

  #
  # remplissage initial des autorisations
  #
  def self.init
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { 'remplissage des autorisations' }
    destroy_all
    acc_roles = Access.access_roles
    controllers_methods = Controller.get_controllers_and_methods
    controllers_methods.each do |controller|
      if controller.method == 'index' || controller.method[0, 6] == 'update' || controller.method[0, 6] == 'create' || controller.method[0, 4] == 'add_' || controller.method == 'select_view'
        # methodes activees apres le formulaire, tt le monde peut, c'est la methode avant formulaire qui est permise ou non (new, new_datafile...)
        roles = nil
      elsif %w[AccessesController DefinitionsController GroupsController RelationsController RolesController SequencesController StatusObjectsController SubscriptionsController TypesobjectsController ViewsController VolumesController].include?(controller.name)
        roles = if controller.method[0, 5] == 'reset'
                  # roles = "admin"
                  roles_admin acc_roles
                else
                  # roles = "admin & (!consultant | !creator)"
                  roles_admins_not_creators_not_consultant acc_roles
                end
      else
        if controller.name == 'SessionsController'
          # roles = "admin | creator | consultant"
          roles = roles_admin_or_creator_or_consultant acc_roles
        elsif %w["WorkitemsController ErrorsController ExpressionsController HistoryController"].include?(controller.name)
          # roles = "(admin | creator) & !consultant"
          roles = roles_admin_or_creator_not_consultant acc_roles
        elsif controller.name == 'QuestionsController'
          roles = nil
          if controller.method == 'edit'
            # roles = "(admin | creator) & !consultant"
            roles = roles_admin_or_creator_not_consultant acc_roles
           end
        elsif controller.name == 'UsersController'
          roles = nil
          if controller.method != 'show' && controller.method[0, 7] != 'account'
            # roles = "admin"
            roles = roles_admin acc_roles
          end
        else
          # les fonctions plm
          if %w[show].include?(controller.method)
            # roles = "admin | designer | valider | consultant"
            roles = roles_admin_or_creator_or_consultant acc_roles
          else
            # roles = "(admin | creator) & !consultant"
            roles = roles_admin_or_creator_not_consultant acc_roles
            # #roles = "("+roles_yes(acc_roles[:cat_admins]) +" | "+ roles_yes(acc_roles[:cat_creators]) +" | "+ roles_yes(acc_roles[:cat_consultants])+ ")"
          end
        end
      end
      exist = find_by_controller_and_roles("#{controller.name}.#{controller.method}", roles)
      next if exist.nil? && roles.nil?
      # LOG.debug(fname){"#{controller.name} #{controller.method}: exist=#{exist} roles=#{roles}"}
      acc = new(controller: controller.name, action: controller.method, roles: roles)
      acc.save
    end
  end

  def self.roles_admin(acc_roles)
    roles_yes(acc_roles[:cat_admins])
  end

  def self.roles_admins_not_creators_not_consultant(acc_roles)
    roles_yes(acc_roles[:cat_admins]) + '& (' + roles_no(acc_roles[:cat_consultants]) + ' | ' + roles_no(acc_roles[:cat_creators]) + ')'
  end

  def self.roles_admin_or_creator_not_consultant(acc_roles)
    '(' + roles_yes(acc_roles[:cat_admins]) + ' | ' + roles_yes(acc_roles[:cat_creators]) + ') & (' + roles_no(acc_roles[:cat_consultants]) + ')'
  end

  def self.roles_admin_or_creator_or_consultant(acc_roles)
    roles_yes(acc_roles[:cat_admins]) + ' | ' + roles_yes(acc_roles[:cat_creators]) + ' | ' + roles_yes(acc_roles[:cat_consultants])
  end
end
