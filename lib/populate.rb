module Populate

  class << self

    def access
      acc_roles = Access.access_roles
      Controller.get_controllers_and_methods.each do |controller|
        roles = nil

        if %w[AccessesController LoginController RolesController RolesUsersController SequencesController].include?(controller.name)
          # fonctions admin
          #roles = "admin & (!designer | !consultant | !valider)"
          roles = "#{Access.roles_yes(acc_roles[:cat_admins])}& (#{Access.roles_no(acc_roles[:cat_consultants])}!#{Access.roles_no(acc_roles[:cat_creators])})"
        else
          case controller.name
          when 'SessionsController'
            # tout le monde peut se deconnecter
            #roles = "admin | designer | consultant | valider"
            roles = "#{Access.roles_yes(acc_roles[:cat_admins])} | #{Access.roles_yes(acc_roles[:cat_creators])} | #{Access.roles_yes(acc_roles[:cat_consultants])}"
          when 'WorkitemsController'
            # tout le monde peut se executer une tache sauf le consultant
            #roles = "(admin | designer | valider) & !consultant"
            roles = "(#{Access.roles_yes(acc_roles[:cat_admins])} | #{Access.roles_yes(acc_roles[:cat_creators])}) & (#{Access.roles_no(acc_roles[:cat_consultants])})"
          when 'QuestionsController'
            # tout le monde peut poser une question, le consultant ne peut repondre
            if controller.method == 'edit'
              #roles = "(admin | designer | valider) & !consultant"
              roles = "(#{Access.roles_yes(acc_roles[:cat_admins])} | #{Access.roles_yes(acc_roles[:cat_creators])}) & (#{Access.roles_no(acc_roles[:cat_consultants])})"
            end
          else
            # les fonctions plm
            if controller.method != 'show'
              #roles = "(admin | designer | valider) & !consultant"
              roles = "(#{Access.roles_yes(acc_roles[:cat_admins])} | #{Access.roles_yes(acc_roles[:cat_creators])}) & (#{Access.roles_no(acc_roles[:cat_consultants])})"
            end
          end
        end

        Access.create(:controller_and_action => "#{controller.name}.#{controller.method}", :roles => roles) unless roles.nil?
      end
    end

  end

end
