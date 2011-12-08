class CreateVernacularStrings < ActiveRecord::Migration
  def up
    execute "CREATE TABLE `vernacular_strings` (
      `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
      `name` varchar(255) COLLATE utf8_bin DEFAULT NULL,
      `uuid` decimal(39,0) NOT NULL UNIQUE,
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `idx_vernacular_strings_1` (`name`),
      KEY `idx_vernacular_strings_2` (`uuid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :vernacular_strings
  end
end
