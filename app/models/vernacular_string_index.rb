class VernacularStringIndex < ActiveRecord::Base
  belongs_to :vernacular_string
  belongs_to :data_source
end
