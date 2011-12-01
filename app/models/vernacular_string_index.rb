class VernacularStringIndex < ActiveRecord::Base
  set_primary_keys :data_source_id, :vernacular_string_id, :taxon_id
  belongs_to :vernacular_string
  belongs_to :data_source
end
