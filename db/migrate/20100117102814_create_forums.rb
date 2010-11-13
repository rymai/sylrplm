class CreateForums < ActiveRecord::Migration
  def self.up
    create_table :forums do |t|
      t.integer :typeobjects_id
      t.integer :statusobject_id
      t.string :subject
      t.text :description
      t.integer :owner_id

      t.timestamps
    end
  end

  def self.down
    drop_table :forums
  end
end
