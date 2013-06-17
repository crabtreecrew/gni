class AddIsSurrogateToNameStrings < ActiveRecord::Migration
  def change
    add_column :name_strings, :surrogate, :boolean, :default => '0'
  end
end
