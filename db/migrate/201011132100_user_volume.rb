class UserVolume < ActiveRecord::Migration
  def self.up
    add_column :users, :volume_id, :integer
  end
 
  def self.down
    remove_column :users, :volume_id
  end
end