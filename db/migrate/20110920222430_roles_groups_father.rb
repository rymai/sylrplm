class RolesGroupsFather < ActiveRecord::Migration
  def self.up

    remove_column :projects, :group
    remove_column :parts, :group
    remove_column :documents, :group
    remove_column :customers, :group
    remove_column :checks, :in_user
    remove_column :checks, :out_user
    remove_column :links, :responsible

    add_column :groups, :father_id, :integer
    add_column :roles, :father_id, :integer

    add_column :checks, :in_user_id, :integer
    add_column :checks, :out_user_id, :integer
    add_column :checks, :in_group_id, :integer
    add_column :checks, :out_group_id, :integer
    add_column :datafiles, :group_id, :integer
    add_column :forum_items, :group_id, :integer
    add_column :forums, :group_id, :integer
    add_column :links, :owner_id, :integer
    add_column :links, :group_id, :integer

    add_column :projects, :group_id, :integer
    add_column :parts, :group_id, :integer
    add_column :documents, :group_id, :integer
    add_column :customers, :group_id, :integer

    add_column :users, :group_id, :integer
    add_column :users, :project_id, :integer

    add_column :checks, :projowner_id, :integer
    add_column :customers, :projowner_id, :integer
    add_column :datafiles, :projowner_id, :integer
    add_column :documents, :projowner_id, :integer
    add_column :forum_items, :projowner_id, :integer
    add_column :forums, :projowner_id, :integer
    add_column :links, :projowner_id, :integer
    add_column :parts, :projowner_id, :integer

    add_column :projects, :typeaccess_id, :integer
    
    add_column :questions, :asker_id, :integer
    add_column :questions, :responder_id, :integer


  end

  def self.down

    add_column :projects, :group, :string
    add_column :parts, :group, :string
    add_column :documents, :group, :string
    add_column :customers, :group, :string
    add_column :checks, :in_user, :integer
    add_column :checks, :out_user, :integer
    add_column :links, :responsible, :string

    remove_column :groups, :father_id
    remove_column :roles, :father_id

    remove_column :checks, :in_user_id
    remove_column :checks, :out_user_id
    remove_column :checks, :in_group_id
    remove_column :checks, :out_group_id
    remove_column :datafiles, :group_id
    remove_column :forum_items, :group_id
    remove_column :forums, :group_id
    remove_column :links, :owner_id
    remove_column :links, :group_id

    remove_column :projects, :group_id
    remove_column :parts, :group_id
    remove_column :documents, :group_id
    remove_column :customers, :group_id

    remove_column :users, :group_id
    remove_column :users, :project_id

    remove_column :checks, :projowner_id
    remove_column :customers, :projowner_id
    remove_column :datafiles, :projowner_id
    remove_column :documents, :projowner_id
    remove_column :forum_items, :projowner_id
    remove_column :forums, :projowner_id
    remove_column :links, :projowner_id
    remove_column :parts, :projowner_id

    remove_column :projects, :typeaccess_id
    
    remove_column :questions, :asker_id
    remove_column :questions, :responder_id
    
  end
end
