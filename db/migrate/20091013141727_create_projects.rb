class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.string :ident
      t.string :type
      t.string :designation
      t.text :description
      t.string :status
      t.string :responsible
      t.string :group
      t.date :date

      t.timestamps
    end
  end

  def self.down
    drop_table :projects
  end
end
