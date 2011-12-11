class CreateRelations < ActiveRecord::Migration
  def self.up
    create_table :relations do |t|
      t.string :name
      t.string :type_id
      t.string :father_plmtype
      t.string :child_plmtype
      t.integer :father_type_id
      t.integer :child_type_id
      t.integer :cardin_occur_min
      t.integer :cardin_occur_max
      t.integer :cardin_use_min
      t.integer :cardin_use_max
      t.timestamps
    end
     
    rename_column :links, :father_type, :father_plmtype
    rename_column :links, :child_type, :child_plmtype
    
    add_column :links, :father_type_id, :integer  
    add_column :links, :child_type_id, :integer  
    add_column :links, :relation_id, :integer  
    
    remove_column :links, :designation
    remove_column :links, :description
    remove_column :links, :name
   
    add_column :users, :typesobject_id, :integer  
  end

  def self.down

    drop_table :relations

    rename_column :links, :father_plmtype, :father_type
    rename_column :links, :child_plmtype, :child_type
    
    remove_column :links, :father_type_id  
    remove_column :links, :child_type_id  
    remove_column :links, :relation_id  
    
    add_column :links, :designation, :string
    add_column :links, :description, :text
    add_column :links, :name, :string  

    remove_column :users, :typesobject_id 

  end
end
