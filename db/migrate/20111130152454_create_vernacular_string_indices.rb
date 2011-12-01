class CreateVernacularStringIndices < ActiveRecord::Migration
  def up
    execute "
      CREATE TABLE `vernacular_string_indices` (
        `data_source_id` int(11) NOT NULL,
        `vernacular_string_id` int(11) UNSIGNED NOT NULL,
        `taxon_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
        `language` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
        `locality` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
        `created_at` datetime DEFAULT timestamp,
        `updated_at` datetime DEFAULT timestamp,
        PRIMARY KEY (`data_source_id`, `vernacular_string_id`, `taxon_id`),
        KEY `idx_vernacular_string_index_records_1` (`vernacular_string_id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :vernacular_string_indices
  end
end
