class Statusobjectspromote < ActiveRecord::Migration
  def self.up
  
      add_column :statusobjects, :promote , :boolean
      add_column :statusobjects, :demote  , :boolean
   end
      
   def self.down
        
        
       remove_column :statusobjects, :promote
       remove_column :statusobjects, :demote
        
        
   end
end
