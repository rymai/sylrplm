class CreateQuestions < ActiveRecord::Migration
  def self.up
    create_table :questions do |t|
      t.string :question
      t.string :answer
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :questions
  end
end
