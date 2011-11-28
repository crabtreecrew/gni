class CreateVernacularNameStrings < ActiveRecord::Migration
  def up
    execute "CREATE TABLE `vernacular_name_strings` (
      `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
      `name` varchar(255) COLLATE utf8_bin DEFAULT NULL,
      `uuid` binary(16) DEFAULT NULL,
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `idx_vernacular_name_strings_1` (`name`),
      KEY `idx_vernacular_name_strings_2` (`uuid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :vernacular_name_strings
  end
end
