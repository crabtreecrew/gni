class AddRanksNameStringIndices < ActiveRecord::Migration
  def change
    add_column :name_string_indices, :classification_path_ranks, :text, :default => nil
  end
end
