class CreateTypesobjects < ActiveRecord::Migration
  def self.up
    create_table :typesobjects do |t|
      t.string :object
      t.string :name
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :typesobjects
  end
end
