class CreateNotifications < ActiveRecord::Migration

  def self.up
    create_table :notifications do |t|
      t.string  :object_type
      t.integer :object_id, :responsible_id
      t.text    :event_type
      t.date    :event_date, :notify_date

      t.timestamps
    end
  end

  def self.down
    drop_table :notifications
  end

end
