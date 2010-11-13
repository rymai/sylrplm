class CreateSequences < ActiveRecord::Migration
  def self.up
    create_table :sequences do |t|
      t.string :object
      t.string :value
      t.string :min
      t.string :max

      t.timestamps
    end
  end

  def self.down
    drop_table :sequences
  end
end
