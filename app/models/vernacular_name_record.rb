class VernacularNameRecord < ActiveRecord::Base
  belongs_to :name_string_index_record
  belongs_to :vernacular_name_string
end
