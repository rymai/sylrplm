class CreateCustomers < ActiveRecord::Migration

  def self.up
    create_table :customers do |t|
      t.integer :owner_id, :typesobject_id, :statusobject_id
      t.string  :ident, :designation, :group
      t.text    :description
      t.date    :date

      t.timestamps
    end
    add_index :customers, :owner_id
    add_index :customers, :ident
    add_index :customers, :typesobject_id
    add_index :customers, :statusobject_id
  end

  def self.down
    drop_table :customers
  end

end
