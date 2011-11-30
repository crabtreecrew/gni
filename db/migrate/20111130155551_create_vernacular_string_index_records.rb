class CreateVernacularStringIndexRecords < ActiveRecord::Migration
  def change
    create_table :vernacular_string_index_records do |t|
      t.references :vernacular_string_index
      t.string :language
      t.string :locality

      t.timestamps
    end
    execute "ALTER TABLE `vernacular_string_index_records` MODIFY COLUMN `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT"
    execute "ALTER TABLE `vernacular_string_index_records` MODIFY COLUMN `vernacular_string_index_id` int(11) UNSIGNED NOT NULL"
    add_index :vernacular_string_index_records, :vernacular_string_index_id, name: :idx_vernacular_string_index_records_1
  end
end
