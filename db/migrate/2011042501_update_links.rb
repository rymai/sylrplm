class UpdateLinks < ActiveRecord::Migration
  def self.up

    rename_column :links, :father_type, :father_type
    rename_column :links, :child_type, :child_type

  end

  def self.down
    rename_column :links, :father_type, :father_type
    rename_column :links, :child_type, :child_type

  end
end
