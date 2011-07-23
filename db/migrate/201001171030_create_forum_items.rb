class CreateForumItems < ActiveRecord::Migration
  def self.up
    create_table :forum_items do |t|
      t.text :message
      t.integer :forum_id
      t.integer :parent_id
      t.integer :owner_id

      t.timestamps
    end
  end

  def self.down
    drop_table :forum_items
  end
end
