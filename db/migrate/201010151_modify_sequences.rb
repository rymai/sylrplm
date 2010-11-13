class ModifySequences < ActiveRecord::Migration
  def self.up
    add_column :sequences, :utility, :string
    add_column :sequences, :modify, :boolean
     
  end

  def self.down
    remove_column :sequences, :utility
    remove_column :sequences, :modify
  end
end
