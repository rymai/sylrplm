class ModifyAccess < ActiveRecord::Migration
  def self.up
    add_column :accesses, :roles, :string
    remove_column :accesses, :role_id
  end

  def self.down
    remove_column :accesses, :roles
    add_column :accesses, :role_id, :integer
  end
end
