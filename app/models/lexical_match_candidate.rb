class LexicalMatchCandidate < ActiveRecord::Base
  set_primary_keys :canonical_form_id, :candidate_name
  belongs_to :canonical_form
end
