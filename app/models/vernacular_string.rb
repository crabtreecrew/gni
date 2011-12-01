class VernacularString < ActiveRecord::Base
  has_many :vernacular_string_indices, :foreign_key => [:data_source_id, :vernacular_string_id, :taxon_id]
end
