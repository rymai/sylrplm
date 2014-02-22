require_dependency 'models/sylrplm_common'
require_dependency 'caboose/access_control'

class Access < ActiveRecord::Base
  include ::Models::SylrplmCommon
	include ::Caboose
	include ::Caboose::AccessControl
	
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

	def self.get_actions_by_roles
		fname= "#{self.class.name}.#{__method__}"
		access_actions=Access.find(:all, :order => "controller, roles, action")
		LOG.debug (fname){"begin list access_actions"}
		controllers_actions={}
		access_actions.each { |aa| 
			controllers_actions[aa.controller]={} if controllers_actions[aa.controller].nil?
			controllers_actions[aa.controller][aa.action]=aa.roles
		}
		actions_by_roles={}
		user=User.find_by_name("syl")
		::Role.find(:all,:order => "title").each { |arole|
			actions_by_roles[arole]={}
			user.role=arole
			#puts "user=#{user}"
			access_actions.each { |aa| 
				#c=c.access_context[:user] c.action_name c.controller_name
				#actions: {:add_datafile=>"(admin | creator | designer | valider | analyst | project_manager | plm_actor) & (!consultant)", :add_docs=>"(admin | creator ...
				c=(eval aa.controller).new
				#puts "access_control:c=#{c.inspect}"
				access_context={:user => user}
				actions=controllers_actions[aa.controller]
				#puts "aa.action=#{aa.action} actions=#{actions}"
				st = allowed?(actions, aa.action, access_context)
				actions_by_roles[arole][aa.controller]=[] if actions_by_roles[arole][aa.controller].nil?
				actions_by_roles[arole][aa.controller]<<aa.action if st==true
				#puts "controller= #{aa.controller} , action= #{aa.action} , roles= #{aa.roles} , user=#{user}, st=#{st}"
			}
		}
		actions_by_roles.each_key { |role|
			puts "******************************************************"
			puts "role=#{role} , #{actions_by_roles[role].count} controllers"
			actions_by_roles[role].each { |controller| 
				unless controller[1].nil?
					if controller[1].count>0
				#puts "controller=#{controller[0]} , #{controller[1].count} actions=#{controller[1]}"
				end
				end
			}
		}
		LOG.debug (fname){"end list access_actions"}
		actions_by_roles
	end
	
	def self.allowed?(actions, action, access_context)
        if actions.has_key? action
          ret=RoleHandler.new.process(actions[action].dup, access_context)
          #puts "allowed:actions.has_key #{action}:#{ret}"
          return ret
        elsif actions.has_key? :DEFAULT
          ret=RoleHandler.new.process(actions[:DEFAULT].dup, access_context)
          #puts "allowed:actions.has_key #{:DEFAULT}:#{ret}"
          return ret
        else
          #puts "allowed:actions.has_no_key #{action} or #{:DEFAULT}"
          return true
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
      ret[:qry] = " controller LIKE :v_filter or action LIKE :v_filter or roles LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
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
  # - creator
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
    puts "acces.init:remplissage des autorisations"
    destroy_all
    acc_roles = Access.access_roles
    #puts "acces.init:#{acc_roles.count} acc_roles"
    controllers_methods=Controller.get_controllers_and_methods
     #puts "acces.init:#{controllers_methods.count} controllers_methods"
    controllers_methods.each do |controller|
    	#puts "acces.init:#{controller.name} #{controller.method}"
    	if controller.method == "index" ||controller.method[0,6] == "update" || controller.method[0,6] == "create" || controller.method[0,4] == "add_" || controller.method == "select_view"
    		# methodes activees apres le formulaire, tt le monde peut, c'est la methode avant formulaire qui est permise ou non (new, new_datafile...)
						roles=nil
      elsif %w[AccessesController DefinitionsController GroupsController RelationsController RolesController SequencesController StatusObjectsController SubscriptionsController TypesobjectsController ViewsController VolumesController ].include?(controller.name)
       # puts "acces.init:#{controller.name} #{controller.method}: fonctions admin"
        if controller.method[0,5] == "reset"
        	#roles = "admin"
        	roles = roles_yes(acc_roles[:cat_admins]) 
        else
        	#roles = "admin & (!consultant | !creator)"
        	roles = roles_yes(acc_roles[:cat_admins]) +"& ("+ roles_no(acc_roles[:cat_consultants]) +" | "+ roles_no(acc_roles[:cat_creators])+ ")"
      	end
      else
        if controller.name == "SessionsController"
        #  puts "acces.init:#{controller.name} #{controller.method}: tout le monde peut se connecter/deconnecter"
          #roles = "admin | creator | consultant"
          roles = roles_yes(acc_roles[:cat_admins]) +" | "+ roles_yes(acc_roles[:cat_creators]) +" | "+ roles_yes(acc_roles[:cat_consultants])
        elsif %w["WorkitemsController ErrorsController ExpressionsController HistoryController"].include?(controller.name)
         # puts "acces.init:#{controller.name} #{controller.method}: tout le monde peut executer une tache sauf le consultant"
          #roles = "(admin | creator) & !consultant"
          roles = "("+roles_yes(acc_roles[:cat_admins]) +" | "+ roles_yes(acc_roles[:cat_creators]) +") & ("+ roles_no(acc_roles[:cat_consultants])+ ")"
        elsif controller.name == "QuestionsController"
          #puts "acces.init:#{controller.name} #{controller.method}: tout le monde peut poser une question, le consultant ne peut repondre"
          roles = nil
          if controller.method == "edit"
            #roles = "(admin | creator) & !consultant"
            roles = "("+roles_yes(acc_roles[:cat_admins]) +" | "+ roles_yes(acc_roles[:cat_creators]) +") & ("+ roles_no(acc_roles[:cat_consultants])+ ")"
          end
        elsif controller.name == "UsersController"
          #puts "acces.init:#{controller.name} #{controller.method}: seulement admin"
          roles=nil
          if controller.method != "show" && controller.method[0,7] != "account"
            #roles = "admin" 
            roles = roles_yes(acc_roles[:cat_admins])
          end
        else
        # les fonctions plm
          if %w["show"].include?(controller.method) 
           # puts "acces.init:#{controller.name} #{controller.method}:fonctions plm:show index: "
            #roles = "admin | designer | valider | consultant"
            roles = roles_yes(acc_roles[:cat_admins]) +" | "+ roles_yes(acc_roles[:cat_creators]) +" | "+ roles_yes(acc_roles[:cat_consultants])
          else
          #puts "acces.init:#{controller.name} #{controller.method}: fonctions plm:autres:#{controller.method}"
          #roles = "(admin | designer | valider | consultant)"
            roles = "("+roles_yes(acc_roles[:cat_admins]) +" | "+ roles_yes(acc_roles[:cat_creators]) +" | "+ roles_yes(acc_roles[:cat_consultants])+ ")"
          end
        end
      end
      exist = find_by_controller_and_roles("#{controller.name}.#{controller.method}",roles)
      #puts "acces.init:#{controller.name} #{controller.method}: exist=#{exist} roles=#{roles}"
      unless exist.nil? && roles.nil?
      	create(:controller_and_action => "#{controller.name}.#{controller.method}", :roles => roles) 
      end
    end
  end

end
