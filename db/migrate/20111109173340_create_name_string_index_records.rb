class CreateNameStringIndexRecords < ActiveRecord::Migration
  def up
    execute "CREATE TABLE `name_string_index_records` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `name_index_id` int(11) DEFAULT NULL,
      `kingdom_id` int(11) DEFAULT NULL,
      `record_hash` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `local_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `global_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      `name_rank_id` int(11) DEFAULT NULL,
      `nomenclatural_code_id` int(11) DEFAULT NULL,
      `original_name_string` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      PRIMARY KEY (`id`),
      KEY `idx_name_index_records_1` (`name_index_id`),
      KEY `idx_name_index_records_2` (`record_hash`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :name_string_index_records
  end
end
