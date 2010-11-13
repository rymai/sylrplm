class CreateTestDatas < ActiveRecord::Migration
  def self.up
    # 100 parts et 10 documents par part
    i=1
    while i <= 100
          ident='part'+(i+100000).to_s
          
          part=Part.create(:ident=>ident, :designation=>'des part'+i.to_s)
          
          j=1
          while j <= 10
            ident_doc='doc'+(j+100000+(i-1)*10).to_s
            
            doc=Document.create(:ident=>ident_doc, :designation=>'des document'+j.to_s)
            puts 'doc:'+ident_doc.to_str
            doc.save!
            part.documents << doc
            j=j+1
          end
      puts 'part:'+ident.to_str
          part.save!
          i=i+1
    end
  end

  def self.down
    parts.delete_all
    documents.delete_all
  end
end
