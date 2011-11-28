class CreateSemanticMeanings < ActiveRecord::Migration
  def change
    create_table :semantic_meanings do |t|
      t.string :name

      t.timestamps
    end
  end
end
