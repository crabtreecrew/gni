class NameString < ActiveRecord::Base
  belongs_to :canonical_form
  has_many :name_string_indices, :foreign_key => [:data_source_id, :name_string_id, :taxon_id]
  belongs_to :parsed_name_string, :foreign_key => :id
  before_create :pre_process_name_string
  after_create :post_process_name_string

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

  def self.get_uuid(a_name_string, as_decimal = true)
    uuid = ::UUID.create_v5(a_name_string, Gni::Config.uuid_namespace)
    as_decimal ? uuid.to_i : uuid.to_s
  end

  def uuid
    res = super
    res ? ::UUID.parse(res.to_s(16)).to_s : nil
  end
  private

  def pre_process_name_string
    self.name = NameString.normalize_space(self.name)
    self.uuid = NameString.get_uuid(self.name)
    self.normalized = NameString.normalize(self.name)
  end
  
  def post_process_name_string
    ParsedNameString.update
  end

end
