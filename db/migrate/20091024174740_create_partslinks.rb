class CreatePartslinks < ActiveRecord::Migration
  def self.up
    create_table :partslinks do |t|
      t.integer :father_id
      t.integer :child_id
      t.string :designation
      t.text :description
      t.float :quantity
      t.string :responsible
      t.string :group
      t.date :date

      t.timestamps
    end
  end

  def self.down
    drop_table :partslinks
  end
end
