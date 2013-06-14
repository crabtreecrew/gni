class CreateProtologs < ActiveRecord::Migration
  def up
    execute "CREATE TABLE `gnub_uuids` (
      `id` decimal(39.0),
      `parent_id` decimal(39.0),
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      PRIMARY KEY (`id`),
      KEY `idx_gnub_uuids_1` (`parent_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :gnub_uuids
  end
end
