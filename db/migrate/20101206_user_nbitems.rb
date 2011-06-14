
class UserNbitems < ActiveRecord::Migration
  def self.up
    add_column :users, :nb_items, :integer
  end

  def self.down
    remove_column :users, :nb_items
  end
end