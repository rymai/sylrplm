class CreateProcessErrors < ActiveRecord::Migration

  # The migration itself is found in the 'ruote' gem ('openwfe/extras/expool/db_errorjournal').
  def self.up
    create_table :process_errors do |t|
      t.string :wfid, :expid, :null => false
      t.text   :svalue, :null => false

      t.timestamp :created_at
    end
    add_index :process_errors, :created_at
    add_index :process_errors, :wfid
    add_index :process_errors, :expid
  end

  def self.down
    drop_table :process_errors
  end

end

