class CreateAccesses < ActiveRecord::Migration
  def self.up
    create_table :accesses do |t|
      t.string :controller
      t.integer :action
      t.integer :role_id

      t.timestamps
    end
  end

  def self.down
    drop_table :accesses
  end
end
