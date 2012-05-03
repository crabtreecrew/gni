class AddFieldToNameStringIndices < ActiveRecord::Migration
  def change
    add_column :name_string_indices, :local_id, :string
  end
end
