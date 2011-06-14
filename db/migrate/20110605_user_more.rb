class UserMore < ActiveRecord::Migration
  def self.up
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :language, :string
    add_column :users, :notification, :integer
    add_column :users, :show_mail, :boolean
    add_column :users, :time_zone, :string
  end

  def self.down
    remove_column :users, :first_name
    remove_column :users, :last_name
    remove_column :users, :language
    remove_column :users, :notification
    remove_column :users, :show_mail
    remove_column :users, :time_zone
  end
end