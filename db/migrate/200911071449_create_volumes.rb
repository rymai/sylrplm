class CreateVolumes < ActiveRecord::Migration
  def self.up
    create_table :volumes do |t|
      t.string :name
      t.text :description
      t.string :directory
      t.string :protocole

      t.timestamps
    end
  end

  def self.down
    drop_table :volumes
  end
end
