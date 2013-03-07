class CreateLexicalMatches < ActiveRecord::Migration
  def up
    execute "CREATE TABLE `lexical_matches` (
      `canonical_form_id` int(11) UNSIGNED NOT NULL,
      `matched_canonical_form_id` int(11) UNSIGNED NOT NULL,
      `edit_distance` int(11) NOT NULL,
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      PRIMARY KEY (`canonical_form_id`, `matched_canonical_form_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :lexical_matches
  end
end
