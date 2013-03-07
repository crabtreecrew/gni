class CanonicalForm < ActiveRecord::Base
  belongs_to :name_string
  has_many :name_strings
  has_many :lexical_match_candidates
end
