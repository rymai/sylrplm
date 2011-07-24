class CreateWorkitems < ActiveRecord::Migration

  # The migration itself is found in the 'ruote' gem ('openwfe/extras/participants/ar_participants').
  def self.up
    create_table :ar_workitems do |t|
      t.string :fei, :wfid, :expid, :wfname, :wfrevision, :participant_name, :store_name
      t.text   :wi_fields
      t.string :activity
      t.text   :keywords

      t.timestamp :dispatch_time, :last_modified
    end

    add_index :ar_workitems, :fei, :unique => true
    add_index :ar_workitems, :wfid
    add_index :ar_workitems, :expid
    add_index :ar_workitems, :wfname
    add_index :ar_workitems, :wfrevision
    add_index :ar_workitems, :participant_name
    add_index :ar_workitems, :store_name
  end

  def self.down
    drop_table :ar_workitems
  end

end

