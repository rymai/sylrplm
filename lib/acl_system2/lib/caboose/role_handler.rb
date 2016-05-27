require_dependency 'acl_system2/lib/caboose/access_control'
require_dependency 'acl_system2/lib/caboose/logic_parser'
module Caboose

  class AccessHandler
    include LogicParser

    def check(key, context)
      false
    end

  end

  class RoleHandler < AccessHandler

    def check(key, context)
      #syl context[:user].roles.map{ |role| role.title.downcase}.include? key.downcase
      if context[:user]!=nil
        context[:user].role.title.downcase==key.downcase
      else
        true
      end
    end

  end # End RoleHandler

end