class VolumeDocuments < ActiveRecord::Migration
  def self.up
      
    add_column :documents, :volume_id, :integer
    execute "alter table documents add constraint fk_document_volume foreign key (volume_id) references volumes(id)"
   end
    
    def self.down
      remove_column :documents, :volume_id
      execute "alter table documents drop foreign key fk_document_volume"
      end
  
end
