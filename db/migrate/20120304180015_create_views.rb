class CreateViews < ActiveRecord::Migration
  def self.up
    create_table :views do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
    add_index :views, :name, :unique => true 
    
    create_table :relations_views, :id => false do |t|
      t.integer :relation_id, :view_id 
      t.timestamps
    end
    add_index :relations_views, [:relation_id, :view_id ], :unique => true
  
  end

  def self.down
    
    drop_table :views
    drop_table :relations_views
    
  end
end
