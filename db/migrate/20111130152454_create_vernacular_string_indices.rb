class CreateVernacularStringIndices < ActiveRecord::Migration
  def change
    create_table :vernacular_string_indices do |t|
      t.references :vernacular_string, nil: false
      t.references :data_source, nil: false

      t.timestamps
    end

    execute "ALTER TABLE `vernacular_string_indices` MODIFY COLUMN `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT"
    execute "ALTER TABLE `vernacular_string_indices` MODIFY COLUMN `vernacular_string_id` int(11) UNSIGNED NOT NULL"
    add_index :vernacular_string_indices, [:vernacular_string_id, :data_source_id], unique: true, name: :idx_vernacular_string_indices_1
    add_index :vernacular_string_indices, :data_source_id, name: :idx_vernacular_string_indices_2
  end
end
