class CreateNameWords < ActiveRecord::Migration
  def change
    create_table :name_words do |t|
      t.string  :word, :nill => false
      t.string  :first_letter, :nill => false
      t.integer :length, :nil => false

      t.timestamps
    end
    execute "ALTER TABLE `name_words` MODIFY COLUMN `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT"
    execute "ALTER TABLE `name_words` MODIFY COLUMN `first_letter` char(1) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL"

    add_index :name_words, :word, :name => :idx_name_words_1, :unique => true
    add_index :name_words, [:first_letter, :length], :name => :idx_name_words_2
  end
end
