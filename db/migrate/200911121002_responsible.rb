class Responsible < ActiveRecord::Migration
 
    def self.up
      
      remove_column( :customers, :responsible )
      remove_column( :documents, :responsible )
      remove_column( :parts, :responsible )
      remove_column( :projects, :responsible )

      add_column( :customers, :owner, :integer )
      add_column( :documents, :owner, :integer )
      add_column( :parts, :owner, :integer )
      add_column( :projects, :owner, :integer )
      
      execute "alter table customers add constraint fk_customer_owner foreign key (owner) references users(id)" 
      execute "alter table documents add constraint fk_document_owner foreign key (owner) references users(id)"
      execute "alter table parts add constraint fk_part_owner foreign key (owner) references users(id)"
      execute "alter table projects add constraint fk_project_owner foreign key (owner) references users(id)"
            
     end
          
     def self.down
       execute "alter table customer drop foreign key fk_customer_owner"
       execute "alter table documents drop foreign key fk_document_owner"
       execute "alter table parts drop foreign key fk_part_owner"
       execute "alter table projects drop foreign key fk_project_owner"
       
       add_column( :customers, :responsible, :string )
       add_column( :documents, :responsible, :string )
       add_column( :parts, :responsible, :string )
       add_column( :projects, :responsible, :string )
       
       remove_column( :customers, :owner, :integer )
       remove_column( :documents, :owner, :integer )
       remove_column( :parts, :owner, :integer )
       remove_column( :projects, :owner, :integer )
          
       
     end
end
