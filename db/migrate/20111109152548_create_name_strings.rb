class CreateNameStrings < ActiveRecord::Migration
  def up
    execute "CREATE TABLE `name_strings` (
      `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
      `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `normalized` varchar(255) CHARACTER SET ascii DEFAULT NULL,
      `is_canonical_form` tinyint(4) DEFAULT NULL,
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      `canonical_form_id` int(11) DEFAULT NULL,
      `has_words` tinyint(1) DEFAULT NULL,
      `uuid` binary(16) DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `idx_name_strings_1` (`name`),
      KEY `idx_name_strings_2` (`canonical_form_id`),
      KEY `idx_name_strings_3` (`normalized`),
      KEY `idx_name_strings_4` (`uuid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :name_strings
  end

end
