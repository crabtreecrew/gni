class NameStringIndex < ActiveRecord::Base
  set_primary_keys :data_source_id, :name_string_id, :taxon_id
  belongs_to :data_source
  belongs_to :name_string
end
