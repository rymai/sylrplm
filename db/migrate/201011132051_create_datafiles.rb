class CreateDatafiles < ActiveRecord::Migration

  def self.up
    create_table :datafiles do |t|
      t.integer :owner_id, :typesobject_id, :document_id, :volume_id, :revision
      t.string  :ident, :filename, :content_type

      t.timestamps
    end
    add_index :datafiles, :document_id
    add_index :datafiles, :ident
  end

  def self.down
    drop_table :datafiles
  end

end
