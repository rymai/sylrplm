module Classes
  module PlmEvent
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      #  access_control [:create, :edit] => 'admin & !blacklist',
      #                 :update => '(admin | moderator) & !blacklist',
      #                 :list => '(admin | moderator | user) & !blacklist'
      def event_manager
        name=controller_name+".event_manager:"
        before_filter do |c|
        #syl
          role_title=""
          if c.access_context[:user]!=nil
            if c.access_context[:user].role!=nil
              role_title=c.access_context[:user].role.title
            end
          end
          puts name+"before: role_title="+role_title+" controller="+c.controller_name+" action="+c.action_name
        end
        after_filter do |c|
        #syl
          role_title=""
          if c.access_context[:user]!=nil
            if c.access_context[:user].role!=nil
              role_title=c.access_context[:user].role.title
            end
          end
          puts name+"after: role_title="+role_title+" controller="+c.controller_name+" action="+c.action_name
        end

      end

      def event_manager_before
        name=controller_name+".event_manager_before:"
        before_filter do |c|
        #syl
          role_title=""
          if c.access_context[:user]!=nil
            if c.access_context[:user].role!=nil
              role_title=c.access_context[:user].role.title
            end
          end
          puts name+"before: role_title="+role_title+" controller="+c.controller_name+" action="+c.action_name
        end

      end

      def event_manager_after
        name=controller_name+".event_manager_after:"
        puts name
        after_filter do |c|
        #syl
          role_title=""
          if c.access_context[:user]!=nil
            if c.access_context[:user].role!=nil
              role_title=c.access_context[:user].role.title
            end
          end
          puts name+"role_title="+role_title+" controller="+c.controller_name+" action="+c.action_name
        end
      end

    # ClassMethods
    end

  end

end
