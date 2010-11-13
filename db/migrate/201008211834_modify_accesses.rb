class ModifyAccesses < ActiveRecord::Migration
  def self.up
    change_column  :accesses, :action, :string
     
  end

  def self.down
    change_column  :accesses, :action, :integer
  end
end
