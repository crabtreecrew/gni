class CreateDataSourceContributors < ActiveRecord::Migration
  def up
    execute "CREATE TABLE `data_source_contributors` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `data_source_id` int(11) DEFAULT NULL,
      `user_id` int(11) DEFAULT NULL,
      `data_source_admin` tinyint(1) DEFAULT NULL,
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `index_data_source_contributors1` (`data_source_id`,`user_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :data_source_contributors
  end
end
