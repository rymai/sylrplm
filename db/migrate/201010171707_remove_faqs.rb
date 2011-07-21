class RemoveFaqs < ActiveRecord::Migration
  def self.up
    drop_table :faqs
    end
  end

  def self.down
    create_table :faqs do |t|
      t.string :faq
      t.string :answer
      t.integer :position

      t.timestamps
    
  end
end
