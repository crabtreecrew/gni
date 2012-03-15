class AddIndexToNameStringIndices < ActiveRecord::Migration
  def change
    add_index :name_string_indices, :taxon_id
  end
end
