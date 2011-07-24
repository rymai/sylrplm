class CreateRolesUsersGroupsDefinitions < ActiveRecord::Migration

  def self.up
    create_table :roles do |t|
      t.string :title
      t.text   :description

      t.timestamps
    end

    create_table :users do |t|
      t.string  :email, :login, :first_name, :last_name, :language, :time_zone, :theme, :hashed_password, :salt
      t.integer :role_id, :volume_id, :nb_items, :notification
      t.boolean :show_mail

      t.timestamps
    end
    add_index :users, :login, :unique => true

    create_table :roles_users, :id => false do |t|
      t.integer :role_id, :user_id

      t.timestamps
    end
    add_index :roles_users, [:role_id, :user_id], :unique => true

    create_table :groups do |t|
      t.string :name

      t.timestamps
    end
    add_index :groups, :name, :unique => true

    create_table :user_groups, :id => false do |t|
      t.integer :user_id, :group_id, :null => false
    end
    add_index :user_groups, [:user_id, :group_id], :unique => true

    create_table :definitions do |t|
      t.string :name, :description, :uri
      t.text   :launch_fields

      t.timestamps
    end
    add_index :definitions, :name, :unique => true

    create_table :group_definitions, :id => false do |t|
      t.integer :group_id, :definition_id

      t.timestamps
    end
    add_index :group_definitions, [:group_id, :definition_id], :unique => true
  end

  def self.down
    drop_table :group_definitions, :definitions, :user_groups, :groups, :roles_users, :users, :roles
  end

end
