class CreateLexicalMatchCandidates < ActiveRecord::Migration
  def up
    execute "CREATE TABLE `lexical_match_candidates` (
      `canonical_form_id` int(11) UNSIGNED NOT NULL,
      `candidate_name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
      `processed` tinyint(1) DEFAULT NULL,
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      PRIMARY KEY (`canonical_form_id`, `candidate_name`),
      KEY `idx_lexical_match_candidates2` (`processed`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
  end

  def down
    drop_table :lexical_match_candidates
  end
end
