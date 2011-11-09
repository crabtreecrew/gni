class CreateCanonicalForms < ActiveRecord::Migration
  def up
    execute "CREATE TABLE `canonical_forms` (
      `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
      `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      `first_letter` varchar(1) COLLATE utf8_unicode_ci DEFAULT NULL,
      `length` int(11) DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `idx_canonical_forms_1` (`name`),
      KEY `idx_canonical_forms_2` (`first_letter`,`length`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :canonical_forms
  end
end
