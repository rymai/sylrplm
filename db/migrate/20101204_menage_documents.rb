class MenageDocuments < ActiveRecord::Migration
  def self.up_inactif
    remove_column :documents, :extension
    remove_column :documents, :repository
    remove_column :documents, :part_id
    remove_column :documents, :data
    remove_column :documents, :filename
    remove_column :documents, :content_type
    remove_column :documents, :volume
    remove_column :documents, :volume_id
    
  end
  def self.up
    
  end
  def self.down
    add_column :documents, :extension, :string
    add_column :documents, :repository, :string
    add_column :documents, :part_id, :integer
    add_column :documents, :data, :binary, :limit => 1.megabyte
    add_column :documents, :filename, :string
    add_column :documents, :content_type, :string
    add_column :documents, :volume, :string
    add_column :documents, :volume_id, :integer
    
  end
  
end
