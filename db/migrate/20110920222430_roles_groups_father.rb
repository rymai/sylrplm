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

    rename_column :volumes, :protocole, :protocol
    
    add_column :accesses, :internal, :boolean
    add_column :checks, :internal, :boolean
    add_column :customers, :internal, :boolean
    add_column :datafiles, :internal, :boolean
    add_column :definitions, :internal, :boolean
    add_column :documents, :internal, :boolean
    add_column :forum_items, :internal, :boolean
    add_column :forums, :internal, :boolean
    add_column :groups, :internal, :boolean
    add_column :links, :internal, :boolean
    add_column :parts, :internal, :boolean
    add_column :projects, :internal, :boolean
    add_column :questions, :internal, :boolean
    add_column :relations, :internal, :boolean
    add_column :roles, :internal, :boolean
    add_column :sequences, :internal, :boolean
    add_column :statusobjects, :internal, :boolean
    add_column :typesobjects, :internal, :boolean
    add_column :users, :internal, :boolean
    add_column :volumes, :internal, :boolean
    
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

    rename_column :volumes, :protocol, :protocole
    
    remove_column :accesses, :internal
    remove_column :checks, :internal
    remove_column :customers, :internal
    remove_column :datafiles, :internal
    remove_column :definitions, :internal
    remove_column :documents, :internal
    remove_column :forum_items, :internal
    remove_column :forums, :internal
    remove_column :groups, :internal
    remove_column :links, :internal
    remove_column :parts, :internal
    remove_column :projects, :internal
    remove_column :questions, :internal
    remove_column :relations, :internal
    remove_column :roles, :internal
    remove_column :sequences, :internal
    remove_column :statusobjects, :internal
    remove_column :typesobjects, :internal
    remove_column :users, :internal
    remove_column :volumes, :internal
    
  end
end
