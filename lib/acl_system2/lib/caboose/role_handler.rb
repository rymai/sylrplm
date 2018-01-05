# frozen_string_literal: true

require_dependency 'acl_system2/lib/caboose/access_control'
require_dependency 'acl_system2/lib/caboose/logic_parser'
module Caboose
  class AccessHandler
    include LogicParser

    def check(_key, _context)
      false
    end
  end

  class RoleHandler < AccessHandler
    def check(key, context)
      # syl context[:user].roles.map{ |role| role.title.downcase}.include? key.downcase
      if !context[:user].nil?
        context[:user].role.title.casecmp(key.downcase).zero?
      else
        true
      end
    end
  end # End RoleHandler
end
