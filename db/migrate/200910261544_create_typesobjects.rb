class CreateTypesobjects < ActiveRecord::Migration

  def self.up
    create_table :typesobjects do |t|
      t.string :object, :name
      t.text   :description

      t.timestamps
    end
    add_index :typesobjects, [:object, :name], :unique => true
  end

  def self.down
    drop_table :typesobjects
  end

end
