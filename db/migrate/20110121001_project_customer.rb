class ProjectCustomer < ActiveRecord::Migration
  def self.up
    remove_column :projects, :customer_id
  end
  
  def self.down
    add_column :projects, :customer_id, :integer
  end
end
