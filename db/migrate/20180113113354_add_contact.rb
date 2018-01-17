class AddContact < ActiveRecord::Migration
    def change
        create_table :contacts do |t|
            t.integer :typesobject_id
            t.string :firstname
            t.string :lastname
            t.string :adress
            t.integer :postalcode
            t.string :town
            t.string :email
            t.string :subject
            t.text :body
            t.string :domain
            t.timestamps
        end
    end
end
