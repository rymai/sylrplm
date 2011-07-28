class CreateHistory < ActiveRecord::Migration

  # The migration itself is found in the 'ruote' gem ('openwfe/extras/expool/db_history').
  def self.up
    create_table :history do |t|
      t.string :source, :event, :null => false
      t.string :wfid, :wfname, :wfrevision, :fei, :participant, :message
      t.text   :tree

      t.timestamp :created_at
    end
    add_index :history, :source
    add_index :history, :event
    add_index :history, :wfid
    add_index :history, :wfname
    add_index :history, :wfrevision
    add_index :history, :participant
    add_index :history, :created_at
  end

  def self.down
    drop_table :history
  end

end

