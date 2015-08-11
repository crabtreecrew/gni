class VernacularStringIndex < ActiveRecord::Base
  set_primary_keys :data_source_id, :vernacular_string_id, :taxon_id
  belongs_to :vernacular_string
  belongs_to :data_source

  def self.vernaculars(data_source_id, taxon_id)
    VernacularStringIndex.connection.select(
      "select vs.name, vsi.language, vsi.locality, vsi.country_code
      from vernacular_string_indices vsi
      join vernacular_strings vs on vs.id = vsi.vernacular_string_id
      where data_source_id = %d and taxon_id = %d" % [data_source_id, taxon_id])
  end
end
