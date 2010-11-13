class CreateStatusobjects < ActiveRecord::Migration
  def self.up
    create_table :statusobjects do |t|
      t.string :object
      t.string :name
      t.integer :rank
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :statusobjects
  end
end
