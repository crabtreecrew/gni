class CreateNameStringIndices < ActiveRecord::Migration
  def up
    execute "CREATE TABLE `name_string_indices` (
      `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
      `name_string_id` int(11) DEFAULT NULL,
      `data_source_id` int(11) DEFAULT NULL,
      `records_hash` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `idx_name_indices_1` (`data_source_id`,`name_string_id`),
      KEY `idx_name_indices_2` (`name_string_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :name_string_indices
  end
end
