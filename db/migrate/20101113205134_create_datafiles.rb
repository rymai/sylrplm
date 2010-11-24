class CreateDatafiles < ActiveRecord::Migration
  def self.up
    create_table :datafiles do |t|
      t.string :ident
      t.string :filename
      t.integer :revision
      t.integer :typesobject_id
      t.string :content_type
      t.integer :owner_id
      t.integer :volume_id

      t.timestamps
    end
  end

  def self.down
    drop_table :datafiles
  end
end
