class Statusobjects < ActiveRecord::Migration
  def self.up
      #remove_column :documents, :status
      #remove_column :parts, :status
      
      add_column :documents, :statusobject_id, :integer
      add_column :parts, :statusobject_id, :integer
      
       #execute "alter table documents drop foreign key fk_document_status"
        execute "alter table documents add constraint fk_document_status foreign key (statusobject_id) references statusobjects(id)"
        #execute "alter table parts drop foreign key fk_part_status"
        execute "alter table parts add constraint fk_part_status foreign key (statusobject_id) references statusobjects(id)"
      end
      
      def self.down
        remove_column :documents, :statusobject_id
        remove_column :parts, :statusobject_id
        execute "alter table documents drop foreign key fk_document_status"
        execute "alter table parts drop foreign key fk_part_status"
        add_column :documents, :status, :string
        add_column :parts, :status, :integer
       end
end
