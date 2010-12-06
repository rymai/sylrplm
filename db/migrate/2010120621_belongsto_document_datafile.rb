class BelongstoDocumentDatafile < ActiveRecord::Migration
  def self.up
      add_column :datafiles, :document_id, :integer
      execute "alter table datafiles add constraint fk_datafile_document foreign key (document_id) references documents(id)"
    end
    
    def self.down
      remove_column :datafiles, :document_id
      execute "alter table datafiles drop foreign key fk_datafile_document"
     end
  
end
