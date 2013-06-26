class CreateGnubUuids < ActiveRecord::Migration
  def up
    execute '
      CREATE TABLE `gnub_uuids` (
      `id` varchar(32) NOT NULL,
      `uuid` decimal(39,0) NOT NULL,
      `parent_uuid` decimal(39,0) DEFAULT NULL,
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      PRIMARY KEY (`id`),
      KEY `idx_gnub_uuids_1` (`uuid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci
    '
  end

  def down
  end
end
