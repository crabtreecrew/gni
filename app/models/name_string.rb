class NameString < ActiveRecord::Base
  belongs_to :canonical_form
  has_many :name_string_indices, :foreign_key => [:data_source_id, :name_string_id, :taxon_id]
  belongs_to :parsed_name_string, :foreign_key => :id

  scope :data_source, joins("join name_string_indices on name_string.id = name_string_indices.name_string_id").where("name_string_indices.data_source_id" => [1,2])

  def self.normalize_space(nstring)
    nstring.gsub(/\s{2,}/, ' ').strip[0...255]
  end

  def self.normalize(nstring)
    Taxamatch::Normalizer.normalize(nstring)[0...255]
  end

  def self.in_data_sources(data_source_ids)
    if data_source_ids.blank?
      where("1 = 1")
    else
      data_source_ids = data_source_ids.select {|i| i.is_a? Fixnum}.join(",")
      joins("join name_string_indices on name_strings.id = name_string_indices.name_string_id").where("data_source_id in (#{data_source_ids})")
    end
  end

  def uuid
    res = super
    res ? res : UUID.create_v5(NameString.normalize_name_string(name), Gni::Config.uuid_namespace).raw_bytes
  end

  def reconcile
    puts name
  end
end
