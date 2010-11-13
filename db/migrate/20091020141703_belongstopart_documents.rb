class BelongstopartDocuments < ActiveRecord::Migration
  def self.up
      add_column :documents, :part_id, :integer
      execute "alter table documents add constraint fk_document_part foreign key (part_id) references parts(id)"
    end
    
    def self.down
      remove_column :documents, :part_id
      execute "alter table documents drop foreign key fk_document_part"
     end
  
end
