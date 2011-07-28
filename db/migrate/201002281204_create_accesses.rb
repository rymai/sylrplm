class CreateAccesses < ActiveRecord::Migration

  def self.up
    create_table :accesses do |t|
      t.string :roles, :controller, :action

      t.timestamps
    end
    add_index :accesses, :controller
  end

  def self.down
    drop_table :accesses
  end

end
