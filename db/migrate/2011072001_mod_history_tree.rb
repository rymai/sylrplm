class ModHistoryTree < ActiveRecord::Migration
  def self.up
      change_column :history, :tree, :text, :limit => 30000
    end
  
    def self.down
      remove_column :history, :tree
    end
end

