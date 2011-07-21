class Statusobjectsbis < ActiveRecord::Migration
  def self.up
    add_column :projects, :statusobject_id, :integer
    add_column :customers, :statusobject_id, :integer

    #execute "alter table documents drop foreign key fk_document_status"
    execute "alter table projects add constraint fk_project_status foreign key (statusobject_id) references statusobjects(id)"
    #execute "alter table parts drop foreign key fk_part_status"
    execute "alter table customers add constraint fk_customer_status foreign key (statusobject_id) references statusobjects(id)"
  end

  def self.down
    remove_column :projects, :statusobject_id
    remove_column :customers, :statusobject_id
    execute "alter table projects drop foreign key fk_project_status"
    execute "alter table customers drop foreign key fk_customer_status"
  end
end
