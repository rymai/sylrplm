class Userhasrole < ActiveRecord::Migration
  def self.up
      add_column :users, :role_id, :integer
      execute "alter table users add constraint fk_user_role foreign key (role_id) references roles(id)"
    end
    
    def self.down
      remove_column :users, :role_id
      execute "alter table users drop foreign key fk_user_role"
     end
  
end
