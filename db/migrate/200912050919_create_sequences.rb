class CreateSequences < ActiveRecord::Migration

  def self.up
    create_table :sequences do |t|
      t.string  :value, :min, :max, :utility
      t.boolean :modify, :sequence

      t.timestamps
    end
    add_index :sequences, :utility, :unique => true
  end

  def self.down
    drop_table :sequences
  end

end
