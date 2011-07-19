class RemoveObsolete < ActiveRecord::Migration
  def self.up
    #drop_table :partslinks
    #drop_table :parts_projects
     
  end

  def self.down
    create_table :partslinks do |t|
      t.integer :father_id
      t.integer :child_id
      t.string :designation
      t.text :description
      t.float :quantity
      t.string :responsible
      t.string :group
      t.date :date

      t.timestamps
    end
    
    create_table :parts_projects do |t|
      t.integer :part_id
      t.integer :project_id
      t.timestamps
    end
    
  end
end
