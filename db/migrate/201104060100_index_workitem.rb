class IndexWorkitem < ActiveRecord::Migration
  def self.up
    remove_index  :ar_workitems,  "index_ar_workitems_on_fei"
    add_index "ar_workitems", ["fei"], :name => "index_ar_workitems_on_fei", :unique => false

  end

  def self.down
    remove_index  :ar_workitems,  "index_ar_workitems_on_fei"
    add_index "ar_workitems", ["fei"], :name => "index_ar_workitems_on_fei", :unique => true
  end
end

