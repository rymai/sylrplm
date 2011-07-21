class ModHistoryTree < ActiveRecord::Migration
  def self.up
      change_column :history, :tree, :text
    end
  
    def self.down
      remove_column :history, :tree
    end
end

