# frozen_string_literal: true

module Caboose
  module AccessControl
    def self.included(subject)
      subject.extend(ClassMethods)
      if subject.respond_to? :helper_method
        subject.helper_method(:permit?)
        subject.helper_method(:restrict_to)
      end
    end

    module ClassMethods
      #  access_control [:create, :edit] => 'admin & !blacklist',
      #                 :update => '(admin | moderator) & !blacklist',
      #                 :list => '(admin | moderator | user) & !blacklist'
      def access_control(actions = {})
        fname = "#{self.class.name}.#{__method__}"
        # LOG.debug(fname) {"args=#{args}"}
        # Add class-wide permission callback to before_filter
        defaults = {}
        if block_given?
          yield defaults
          default_block_given = true
        end
        before_filter do |c|
          c.default_access_context = defaults if default_block_given
          @access = AccessSentry.new(c, actions)
          # syl
          role_title = ''
          unless c.access_context[:user].nil?
            unless c.access_context[:user].role.nil?
              role_title = c.access_context[:user].role.title
            end
          end
          action = actions[c.action_name.to_sym]
          # puts "access_control:actions=#{actions.inspect} "
          ### LOG.debug(fname) {"action=#{action.inspect}"}
          # ####puts "access_control:c=#{c.inspect} "
          # puts "access_control:c.action=#{c.action_name} "
          # puts "access_control:c.access_context=#{c.access_context.inspect}"
          # puts "access_control:role_title=#{role_title}"
          if @access.allowed?(c.action_name)
            c.send(:permission_granted) if c.respond_to? :permission_granted
          # puts "access_control:allowed #{c.controller_name}/#{c.action_name} to #{role_title}"
          else
            if c.respond_to? :permission_denied
              # puts "access_control:not allowed #{c.controller_name}/#{c.action_name} permission_denied to #{role_title}"
              c.send(:permission_denied, role_title, c.controller_name, c.action_name)
            else
              # puts "access_control:not allowed #{c.controller_name}/#{c.action_name} not permission_denied to #{role_title}"
              c.send(:render_text, role_title, c.controller_name, c.action_name)
            end
          end
        end
        # puts "access_control:fin"
      end
    end # module ClassMethods

    # return the active access handler, fallback to RoleHandler
    # implement #retrieve_access_handler to return non-default handler
    def access_handler
      @handler ||= if respond_to?(:retrieve_access_handler)
                     retrieve_access_handler
                   else
                     RoleHandler.new
                   end
    end

    # the current access context; will be created if not setup
    # will add @current_user and merge any other elements of context
    def access_context(context = {})
      default_access_context.merge(context)
    end

    def default_access_context
      @default_access_context ||= {}
      # if respond_to?(:current_user)
      @default_access_context[:user] = send(:current_user)
      @default_access_context
    end

    def default_access_context=(defaults)
      @default_access_context = defaults
    end

    def permit?(logicstring, context = {})
      access_handler.process(logicstring, access_context(context))
    end

    # restrict_to "admin | moderator" do
    #   link_to "foo"
    # end
    def restrict_to(logicstring, context = {})
      return false if @current_user.nil?
      result = ''
      if permit?(logicstring, context)
        result = yield if block_given?
      end
      result
    end

    class AccessSentry
      def initialize(subject, actions = {})
        @actions = actions.each_with_object({}) do |current, auth|
          [current.first].flatten.each { |action| auth[action] = current.last }
        end
        @subject = subject
      end

      def allowed?(action)
        if @actions.key? action.to_sym
          ret = @subject.access_handler.process(@actions[action.to_sym].dup, @subject.access_context)
          # puts "allowed:actions.has_key #{action}:#{ret}"
          ret
        elsif @actions.key? :DEFAULT
          ret = @subject.access_handler.process(@actions[:DEFAULT].dup, @subject.access_context)
          # puts "allowed:actions.has_key #{:DEFAULT}:#{ret}"
          ret
        else
          # puts "allowed:actions.has_no_key #{action} or #{:DEFAULT}"
          true
        end
      end
    end # AccessSentry
  end # AccessControl
end # Caboose
