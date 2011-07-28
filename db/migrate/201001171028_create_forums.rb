class CreateForums < ActiveRecord::Migration

  def self.up
    create_table :forums do |t|
      t.integer :owner_id, :typesobject_id, :statusobject_id
      t.string  :subject
      t.text    :description

      t.timestamps
    end
    add_index :forums, :owner_id
    add_index :forums, :statusobject_id
    add_index :forums, :typesobject_id

    create_table :forum_items do |t|
      t.integer :forum_id, :parent_id, :owner_id
      t.text    :message

      t.timestamps
    end
    add_index :forum_items, :forum_id
    add_index :forum_items, :parent_id
    add_index :forum_items, :owner_id
  end

  def self.down
    drop_table :forum_items
    drop_table :forums
  end

end
