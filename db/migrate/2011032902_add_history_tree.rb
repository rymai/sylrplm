class AddHistoryTree < ActiveRecord::Migration
  def self.up
      add_column :history, :tree, :string
    end
  
    def self.down
      remove_column :history, :tree
    end
end

