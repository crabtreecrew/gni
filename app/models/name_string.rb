class NameString < ActiveRecord::Base
  belongs_to :canonical_form
  has_many :name_string_indices, :foreign_key => [:data_source_id, :name_string_id, :taxon_id]
  belongs_to :parsed_name_string, :foreign_key => :id

  def self.normalize(nstring)
    nstring.gsub(/\s{2,}/, ' ').strip
  end

  def parsed
    @parsed ||= JSON.parse(self.parsed_name_string.data, symbolize_names: true)[:scientificName] rescue nil
  end
end
