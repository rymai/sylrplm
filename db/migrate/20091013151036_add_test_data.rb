class AddTestData < ActiveRecord::Migration
  def self.up
    doc=Document.create(:ident=>'doc1111', :designation=>'des doc1111')
    doc.save!
    doc=Document.create(:ident=>'doc2222', :designation=>'des doc2222')
    doc.save!
    doc=Document.create(:ident=>'img3333', :designation=>'des img3333')
    doc.save!
  end

  def self.down
    documents.delete_all
  end
end
