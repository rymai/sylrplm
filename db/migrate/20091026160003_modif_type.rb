class ModifType < ActiveRecord::Migration
  def self.up
    remove_column :documents, :type
    remove_column :parts, :type
    remove_column :projects, :type
    remove_column :customers, :type
    
    add_column :documents, :typesobject_id, :integer
    add_column :parts, :typesobject_id, :integer
    add_column :projects, :typesobject_id, :integer
    add_column :customers, :typesobject_id, :integer
     
    #execute "alter table documents drop foreign key fk_document_type"
      execute "alter table documents add constraint fk_document_type foreign key (typesobject_id) references typesobjects(id)"
      #execute "alter table parts drop foreign key fk_part_type"
      execute "alter table parts add constraint fk_part_type foreign key (typesobject_id) references typesobjects(id)"
      execute "alter table projects add constraint fk_project_type foreign key (typesobject_id) references typesobjects(id)"
      execute "alter table customers add constraint fk_customer_type foreign key (typesobject_id) references typesobjects(id)"
    end
    
    def self.down
      remove_column :documents, :typesobject_id
      remove_column :parts, :typesobject_id
      remove_column :projects, :typesobject_id
      remove_column :customers, :typesobject_id
      execute "alter table documents drop foreign key fk_document_type"
      execute "alter table parts drop foreign key fk_part_type"
      execute "alter table projects drop foreign key fk_project_type"
      execute "alter table customers drop foreign key fk_customer_type"
      add_column :documents, :type, :string
      add_column :parts, :type, :integer
      add_column :projects, :type, :string
      add_column :customers, :type, :string
     end
  
end
