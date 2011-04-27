class CreateLinks < ActiveRecord::Migration
  def self.up
    create_table :links do |t|
      t.string :father_type
      t.string :child_type
      t.integer :father_id
      t.integer :child_id
      t.string :name
      t.string :designation
      t.text :description
      t.string :responsible
      t.string :group
      t.date :date

      t.timestamps
    end
  end

  def self.down
    drop_table :links
  end
end
