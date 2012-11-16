class LexicalMatches < ActiveRecord::Base
  set_primary_keys :canonical_form_id, :matched_canonical_form_id
  belongs_to :canonical_form
end
