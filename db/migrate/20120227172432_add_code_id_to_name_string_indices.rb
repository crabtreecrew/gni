class AddCodeIdToNameStringIndices < ActiveRecord::Migration
  def change
    add_column :name_string_indices, :nomenclatural_code_id, :integer
  end
end
