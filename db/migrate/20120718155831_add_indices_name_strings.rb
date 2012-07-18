class AddIndicesNameStrings < ActiveRecord::Migration
  def up
    remove_index :name_strings, :name => 'idx_name_strings_4'
    add_index :name_strings, :parser_version, :name => 'idx_name_strings_4'
    add_index :name_strings, :has_words, :name => 'idx_name_strings_5'
  end

  def down
    remove_index :name_strings, :name => 'idx_name_strings_5'
    remove_index :name_strings, :name => 'idx_name_strings_4'
    add_index :name_strings, :uuid, :name => 'idx_name_strings_4'
  end
end
