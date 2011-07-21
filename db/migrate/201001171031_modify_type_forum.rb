class ModifyTypeForum < ActiveRecord::Migration
  def self.up
    remove_column :forums, :typeobjects_id
        
        
        add_column :forums, :typesobject_id, :integer
    
  end

  def self.down
    remove_column :forums, :typesobject_id
    add_column  :forums, :typeobjects_id, :integer
        
        
        
  end
end
