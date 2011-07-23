class ModifyUser < ActiveRecord::Migration
  def self.up
    rename_column :users, :name, :login
    rename_column :users, :mail, :email
    rename_column :roles, :name, :title
  end

  def self.down
  end
end
