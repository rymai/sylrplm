class CreateLinks < ActiveRecord::Migration

  def self.up
    create_table :links do |t|
      t.string  :father_type, :child_type
      t.integer :father_id, :child_id
      t.string  :name, :designation, :responsible
      t.text    :description

      t.timestamps
    end
    add_index :links, [:father_type, :father_id]
    add_index :links, [:child_type, :child_id]
  end

  def self.down
    drop_table :links
  end

end
