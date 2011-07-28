class CreateParts < ActiveRecord::Migration

  def self.up
    create_table :parts do |t|
      t.integer :owner_id, :typesobject_id, :statusobject_id
      t.string  :ident, :revision, :designation, :group
      t.text    :description
      t.date    :date

      t.timestamps
    end
    add_index :parts, :owner_id
    add_index :parts, :ident
    add_index :parts, :typesobject_id
    add_index :parts, :statusobject_id
  end

  def self.down
    drop_table :parts
  end

end
