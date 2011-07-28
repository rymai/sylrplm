class CreateExpressions < ActiveRecord::Migration

  def self.up
    create_table :expressions do |t|
      t.string :fei, :wfid, :expid,:exp_class, :null => false
      t.text   :svalue, :text, :null => false
    end
    add_index :expressions, :fei
    add_index :expressions, :wfid
    add_index :expressions, :expid
    add_index :expressions, :exp_class
  end

  def self.down
    drop_table :expressions
  end

end
