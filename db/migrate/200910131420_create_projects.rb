class CreateProjects < ActiveRecord::Migration

  def self.up
    create_table :projects do |t|
      t.integer :owner_id, :typesobject_id, :statusobject_id
      t.string  :ident, :designation, :group
      t.text    :description
      t.date    :date

      t.timestamps
    end
    add_index :projects, :owner_id
    add_index :projects, :ident
    add_index :projects, :typesobject_id
    add_index :projects, :statusobject_id
  end

  def self.down
    drop_table :projects
  end

end
