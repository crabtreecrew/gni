class NameString < ActiveRecord::Base
  belongs_to :canonical_form
  has_many :name_string_indices, :foreign_key => [:data_source_id, :name_string_id, :taxon_id]
  def self.normalize(nstring)
    nstring.gsub(/\s{2,}/, ' ').strip
  end
end
