class CreateParsedNameStrings < ActiveRecord::Migration
  def change
    create_table :parsed_name_strings do |t|
      t.string :canonical_form
      t.string :parser_version
      t.boolean :parsed
      t.integer :pass_num # 0 - is clean 1 - dirty, 2 - salvage canonical parsings
      t.text :data
      t.timestamps
    end

    execute "ALTER TABLE `parsed_name_strings` MODIFY COLUMN `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT"
    add_index :parsed_name_strings, :parser_version, :name => :idx_parsed_name_strings_1
    add_index :parsed_name_strings, :pass_num, :name => :idx_parsed_name_strings_2
  end
end
