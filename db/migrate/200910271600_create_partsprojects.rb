class CreatePartsprojects < ActiveRecord::Migration
  def self.up
    create_table :parts_projects do |t|
      t.integer :part_id
      t.integer :project_id
      t.timestamps
    end
  end

  def self.down
    drop_table :parts_projects
  end
end
