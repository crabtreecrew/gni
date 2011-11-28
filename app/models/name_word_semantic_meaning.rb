class NameWordSemanticMeaning < ActiveRecord::Base
  belongs_to :name_word
  belongs_to :name_string
  belongs_to :semantic_meaning
end
