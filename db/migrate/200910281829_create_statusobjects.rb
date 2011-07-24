class CreateStatusobjects < ActiveRecord::Migration

  def self.up
    create_table :statusobjects do |t|
      t.string  :object, :name
      t.text    :description
      t.integer :rank
      t.boolean :promote, :demote

      t.timestamps
    end
    add_index :statusobjects, [:object, :rank, :name], :unique => true
  end

  def self.down
    drop_table :statusobjects
  end

end
