class CreateDocuments < ActiveRecord::Migration

  def self.up
    create_table :documents do |t|
      t.integer :owner_id, :typesobject_id, :statusobject_id
      t.string  :ident, :revision, :designation, :group
      t.text    :description
      t.date    :date

      t.timestamps
    end
    add_index :documents, :owner_id
    add_index :documents, :ident
    add_index :documents, :typesobject_id
    add_index :documents, :statusobject_id
  end

  def self.down
    drop_table :documents
  end

end
