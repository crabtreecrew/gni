class AddFieldToNameStrings < ActiveRecord::Migration
  def change
    add_column :name_strings, :parser_version, :integer, :default => '10000'
  end
end
