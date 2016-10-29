class CreateNameStringIndices < ActiveRecord::Migration
  def up
    execute "CREATE TABLE `name_string_indices` (
      `data_source_id` int(11) NOT NULL,
      `name_string_id` int(11) UNSIGNED NOT NULL,
      `taxon_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
      `global_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `rank` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `accepted_taxon_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `synonym` set('synonym', 'lexical','homotypic', 'heterotypic') DEFAULT NULL,
      `classification_path` text DEFAULT NULL,
      `classification_path_ids` text DEFAULT NULL,
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      PRIMARY KEY (`data_source_id`,`name_string_id`, `taxon_id`),
      KEY `idx_name_index_records_1` (`name_string_id`),
      KEY `idx_name_index_records_3` (`synonym`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :name_string_indices
  end
end
