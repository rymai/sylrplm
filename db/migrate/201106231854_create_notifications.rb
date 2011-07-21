class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.string :object_type
      t.integer :object_id
      t.date :event_date
      t.text :event_type
      t.integer :responsible_id
      t.date :notify_date

      t.timestamps
    end
  end

  def self.down
    drop_table :notifications
  end
end
