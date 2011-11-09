class CreateDataSources < ActiveRecord::Migration
  def up
    execute "CREATE TABLE `data_sources` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `logo_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `web_site_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `data_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
      `refresh_period_days` int(11) DEFAULT '14',
      `name_strings_count` int(11) DEFAULT '0',
      `data_hash` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
      `unique_names_count` int(11) DEFAULT '0',
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `index_data_sources_1` (`data_url`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :data_sources
  end
end
