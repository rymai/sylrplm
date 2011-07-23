class CreateCustomers < ActiveRecord::Migration
  def self.up
    create_table :customers do |t|
      t.string :ident
      t.string :type
      t.string :designation
      t.text   :description
      t.string :responsible
      t.string :group
      t.date   :date

      t.timestamps
    end
  end

  def self.down
    drop_table :customers
  end
end
