module Classes::PlmEvent
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    #  access_control [:create, :edit] => 'admin & !blacklist',
    #                 :update => '(admin | moderator) & !blacklist',
    #                 :list => '(admin | moderator | user) & !blacklist'
    def event_manager_before
      name=controller_class_name+".event_manager_before:"
      puts name
      before_filter do |c|
        #syl
        role_title=""
        if c.access_context[:user]!=nil
          if c.access_context[:user].role!=nil
            role_title=c.access_context[:user].role.title
          end
        end
        puts name+c.inspect+":"
      end
    end
    def event_manager_after
      name=controller_class_name+".event_manager_after:"
      puts name
      before_filter do |c|
        #syl
        role_title=""
        if c.access_context[:user]!=nil
          if c.access_context[:user].role!=nil
            role_title=c.access_context[:user].role.title
          end
        end
        puts name+c.inspect+":"
      end
    end
  end # ClassMethods

end #
