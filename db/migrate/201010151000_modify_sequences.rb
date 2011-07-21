class ModifySequences < ActiveRecord::Migration
  def self.up
    add_column :sequences, :utility, :string
    add_column :sequences, :modify, :boolean
    add_column :sequences, :sequence, :boolean
    remove_column :sequences, :object
  end

  def self.down
    remove_column :sequences, :utility
    remove_column :sequences, :modify
    remove_column :sequences, :sequence
    add_column :sequences, :object, :string
  end
end
