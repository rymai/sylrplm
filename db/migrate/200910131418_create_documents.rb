class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.string :ident
      t.string :type
      t.string :revision
      t.string :designation
      t.text :description
      t.string :extension
      t.string :repository
      t.string :status
      t.string :responsible
      t.string :group
      t.date :date

      t.timestamps
    end
  end

  def self.down
    drop_table :documents
  end
end
