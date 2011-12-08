class NameString < ActiveRecord::Base
  belongs_to :canonical_form
  has_many :name_string_indices, :foreign_key => [:data_source_id, :name_string_id, :taxon_id]
  belongs_to :parsed_name_string, :foreign_key => :id

  def self.normalize_space(nstring)
    nstring.gsub(/\s{2,}/, ' ').strip
  end

  def uuid
    res = super
    res ? res : UUID.create_v5(NameString.normalize_name_string(name), GNA_NAMESPACE).raw_bytes
  end
end
