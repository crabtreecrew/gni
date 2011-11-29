class CreateVernacularNameRecords < ActiveRecord::Migration
  def change
    create_table :vernacular_name_records do |t|
      t.references :name_string_index_record
      t.references :vernacular_name_string
      t.string :language
      t.string :locality

      t.timestamps
    end
    execute "ALTER TABLE `vernacular_name_records` MODIFY COLUMN `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT"
    add_index :vernacular_name_records, :name_string_index_record_id
    add_index :vernacular_name_records, :vernacular_name_string_id
  end
end
