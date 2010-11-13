class BelongstocustomerProjects < ActiveRecord::Migration
  def self.up
      add_column :projects, :customer_id, :integer
      execute "alter table projects add constraint fk_project_customer foreign key (customer_id) references customers(id)"
    end
    
    def self.down
      remove_column :projects, :customer_id
      execute "alter table projects drop foreign key fk_project_customer"
     end
     
     
  
end
