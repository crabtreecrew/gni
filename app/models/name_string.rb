class NameString < ActiveRecord::Base
  belongs_to :canonical_form
  has_many :name_string_indices, :foreign_key => [:data_source_id, :name_string_id, :taxon_id]
  belongs_to :parsed_name_string, :foreign_key => :id
  before_create :pre_process_name_string
  after_create :post_process_name_string

  scope :data_source, joins("join name_string_indices on name_string.id = name_string_indices.name_string_id").where("name_string_indices.data_source_id" => [1,2])

  def self.parse_uuid(decimal_uuid)
    uuid_hex = decimal_uuid.to_i.to_s(16)
    if uuid_hex.size != 32
      zeros = '0' * (32 - uuid_hex.size)
      uuid_hex = zeros + uuid_hex
    end
    ::UUID.parse(uuid_hex).to_s
  end

  def self.kill_orphans
    #we only remove orphans which parser could not process, keep the rest, because there is a good chance they might be reentered into the system.
    NameString.connection.execute('delete from name_strings where id not in (select name_string_id from name_string_indices) and id in (select id from parsed_name_strings where parsed=0)')
    NameString.connection.execute('delete from parsed_name_strings where id not in (select id from name_strings)')
  end


  def self.normalize_space(nstring)
    nstring.gsub(/\s{1,}/, ' ').strip[0...255]
  end

  def self.normalize(nstring)
    return '' if nstring == nil || nstring.empty?
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
    res ? NameString.parse_uuid(res) : nil
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
