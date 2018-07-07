# frozen_string_literal: true

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
        name = controller_class_name + '.event_manager:'
        before_filter do |c|
          # syl
          role_title = ''
          unless c.access_context[:user].nil?
            unless c.access_context[:user].role.nil?
              role_title = c.access_context[:user].role.title
            end
          end
        end
        after_filter do |c|
          # syl
          role_title = ''
          unless c.access_context[:user].nil?
            unless c.access_context[:user].role.nil?
              role_title = c.access_context[:user].role.title
            end
          end
        end
      end

      def event_manager_before
        name = controller_class_name + '.event_manager_before:'
        before_filter do |c|
          # syl
          role_title = ''
          unless c.access_context[:user].nil?
            unless c.access_context[:user].role.nil?
              role_title = c.access_context[:user].role.title
            end
          end
         end
      end

      def event_manager_after
        name = controller_class_name + '.event_manager_after:'
        after_filter do |c|
          # syl
          role_title = ''
          unless c.access_context[:user].nil?
            unless c.access_context[:user].role.nil?
              role_title = c.access_context[:user].role.title
            end
          end
        end
      end

      # ClassMethods
    end
  end
end
