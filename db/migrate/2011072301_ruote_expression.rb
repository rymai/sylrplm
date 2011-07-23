require 'openwfe/extras/expool/ar_expstorage'
#class RuoteExpression < OpenWFE::Extras::ExpressionTables
class RuoteExpression < ActiveRecord::Migration
  def self.up

      create_table :expressions do |t|

        t.column :fei, :string, :null => false
        t.column :wfid, :string, :null => false
        t.column :expid, :string, :null => false
        #t.column :wfname, :string, :null => false
        t.column :exp_class, :string, :null => false

        #t.column :svalue, :text, :null => false
        #TODO syl pb heroku t.column :svalue, :text, :null => false, :limit => 1024 * 1024
        t.column :svalue, :text, :null => false
          #
          # 'value' could be reserved, using 'svalue' instead
          #
          # :limit patch by Maarten Oelering (a greater value
          # could be required in some cases)
      end
      add_index :expressions, :fei
      add_index :expressions, :wfid
      add_index :expressions, :expid
      #add_index :expressions, :wfname
      add_index :expressions, :exp_class
    end

    def self.down
end
