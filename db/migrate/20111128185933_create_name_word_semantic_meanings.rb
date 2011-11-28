class CreateNameWordSemanticMeanings < ActiveRecord::Migration
  def change
    create_table :name_word_semantic_meanings do |t|
      t.references :name_word
      t.references :name_string
      t.references :semantic_meaning
      t.integer :name_string_position

      t.timestamps
    end
    execute "ALTER TABLE `name_words` MODIFY COLUMN `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT"
    add_index :name_word_semantic_meanings, [:name_word_id, :name_string_id, :name_string_position], :name => :idx_name_words_semantics_1, :unique => true
    add_index :name_word_semantic_meanings, :name_string_id, :name => :idx_name_words_semantics_2
  end
end
