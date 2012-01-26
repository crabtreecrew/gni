# encoding: utf-8
require 'ruby-prof'

class DwcaImporter < ActiveRecord::Base
  belongs_to :data_source

  unless defined? DWCA_IMPORTER_DEFINED
    NAME_BATCH_SIZE = 10_000
    DWCA_IMPORTER_DEFINED = true
  end
  @queue = :dwca_importer

  def self.perform(dwca_importer_id)
    gi = DwcaImporter.find(gnaclr_importer_id)
    gi.import
  end

  def get_time(now)
    new_now = Time.now
    puts new_now - now
    new_now
  end

  def import
    begin
      fetch_tarball
      read_tarball
      store_name_strings
      store_vernacular_strings
      parse_name_strings
      store_index
      publish_new_data
      true
    rescue Exception => e
      DarwinCore.logger_write(@dwc.object_id, "Import Failed: %s" % e.message)
      false
    end
  end

  private

  def read_metadata
    DarwinCore.logger_write(@dwc.object_id, "Reading metadata")
    data_source.title = @dwc.eml.title unless @dwc.eml.title.blank?
    if @dwc.eml.abstract.is_a?(Hash) && @dwc.eml.abstract.has_key?(:para)
      data_source.description = @dwc.eml.abstract[:para].to_s.strip
    elsif @dwc.eml.abstract.is_a?(String) && !@dwc.eml.abstract.strip.blank?
      data_source.description = @dwc.eml.abstract.strip
    end
    data_source.save!
  end

  def fetch_tarball
    if url.match(/^\s*http:\/\//)
      dlr = Gni::Downloader.new(url, tarball_path)
      downloaded_length = dlr.download_with_percentage do |r|
        msg = sprintf("Downloaded %.0f%% in %.0f seconds ETA is %.0f seconds", r[:percentage], r[:elapsed_time], r[:eta])
        JobLog.create(:type => "DwcaImporterLog", :job_id => self.id, :message => msg)
      end
      JobLog.create(:type => "DwcaImporterLog", :job_id => self.id, :message => "Download finished, Size: %s" % downloaded_length)
    else
      Kernel.system("curl -s #{url} > #{tarball_path}")
    end
  end

  def read_tarball
    @db = NameString.connection
    @dwc               = DarwinCore.new(tarball_path)
    DarwinCore.logger.subscribe(:an_object_id => @dwc.object_id, :job_id => self.id, :type => 'DwcaImporterLog')
    DarwinCore.logger_write(@dwc.object_id, "Import started for data source %s" % data_source.title)
    read_metadata
    normalizer        = DarwinCore::ClassificationNormalizer.new(@dwc)
    @data = normalizer.normalize(:with_canonical_names => false);
    @tree             = normalizer.tree
    @name_strings     = normalizer.name_strings(with_hash: true)
    @vernacular_strings = normalizer.vernacular_name_strings(with_hash: true)
    @languages        = {}
    @record_count     = 0
    @update_canonical_list = {}
  end

  def store_name_strings
    DarwinCore.logger_write(@dwc.object_id, "Populating local database")
    DarwinCore.logger_write(@dwc.object_id, "Processing scientific name strings")
    count = 0
    @name_strings.keys.in_groups_of(NAME_BATCH_SIZE).each do |group|
      count += NAME_BATCH_SIZE
      now = time_string
      group = group.compact.map do |name_string|
        name = NameString.normalize_space(name_string)
        uuid = get_uuid(name)
        @name_strings[name_string] = { normalized: @db.quote(name) }
        tm_normalized = @db.quote(NameString.normalize(name))
        "%s, %s, %s, '%s','%s'" % [@name_strings[name_string][:normalized], uuid, tm_normalized, now, now]
      end.join('), (')
      @db.execute "INSERT IGNORE INTO name_strings (name, uuid, normalized, created_at, updated_at) VALUES (#{group})"
      DarwinCore.logger_write(@dwc.object_id, "Traversed %s scientific name strings" % count)
    end
  end

  def store_vernacular_strings
    DarwinCore.logger_write(@dwc.object_id, "Processing vernacular name strings")
    count = 0
    @vernacular_strings.keys.in_groups_of(NAME_BATCH_SIZE).each do |group|
      count += NAME_BATCH_SIZE
      now = time_string
      group = group.compact.map do |name_string|
        name = NameString.normalize_space(name_string)
        @vernacular_strings[name_string] = { normalized: @db.quote(name) }
        uuid = get_uuid(name)
        "%s, %s, '%s','%s'" % [@vernacular_strings[name_string][:normalized], uuid, now, now]
      end.join('), (')
      @db.execute "INSERT IGNORE INTO vernacular_strings (name, uuid, created_at, updated_at) VALUES (#{group})"
      DarwinCore.logger_write(@dwc.object_id, "Traversed %s vernacular name strings" % count)
    end
  end

  def parser_error(name)
    { scientificName: { parsed: false, verbatim: name,  error: 'Parser error', parser_run: 0 } }
  end

  def parse_name_strings
    DarwinCore.logger_write(@dwc.object_id, "Parsing incoming strings")
    count = 0
    while true do
      now = time_string
      q = "SELECT id, name FROM name_strings WHERE has_words IS NULL LIMIT %s" % NAME_BATCH_SIZE
      parser = ScientificNameParser.new
      res = @db.select_rows(q)
      set_size = res.size
      break if set_size == 0
      ids = []
      names = []
      res = res.map { |id, name| [id, (parser.parse(name) rescue parser_error(name))] }
      words = []
      sql_data = res.map do |id, data|
        parsed = data[:scientificName][:parsed] ? 1 : 0
        collect_words(words, id, data) if parsed == 1
        parser_run = data[:scientificName][:parser_run].to_i
        parser_version = data[:scientificName][:parser_version]
        canonical = parsed == 1 ? @db.quote(data[:scientificName][:canonical]) : "NULL"
        dump_data = @db.quote(data.to_json)
        "%s, %s, '%s', %s, %s, %s, '%s', '%s'" % [id, parsed, parser_version, parser_run, canonical, dump_data, now, now]
      end.join("),(")
      @db.execute("INSERT IGNORE INTO parsed_name_strings (id, parsed, parser_version, pass_num, canonical_form, data, created_at, updated_at) VALUES (%s)" % sql_data)
      @db.execute("UPDATE name_strings SET has_words = 1 WHERE id IN (#{res.map{|i| i[0]}.join(",")})")
      insert_words(words) if words.size > 0
      process_canonical_form(res)
      count += set_size
      DarwinCore.logger_write(@dwc.object_id, "Parsed %s names" % count)
    end
  end

  def collect_words(words, name_string_id, parsed_data)
    name_string = parsed_data[:scientificName][:verbatim]
    pos = parsed_data[:scientificName][:positions]
    pos.keys.each do |key|
      word_start = key.to_i
      word_end = pos[key][1]
      length = word_end - word_start
      word = Taxamatch::Normalizer.normalize_word(name_string[word_start..word_end])
      word_type = SemanticMeaning.send(pos[key][0]).id
      first_letter = word[0] ? word[0] : ""
      words << [@db.quote(word), "'" + first_letter + "'", word.size, word_start, length, name_string_id, word_type]
    end
  end

  def insert_words(words)
    insert_words = words.map { |w| w[0..2].join(",") }.join("),(")
    @db.execute("INSERT IGNORE INTO name_words (word, first_letter, length) VALUES (#{insert_words})")
    insert_semantic_words = words.map do |data|
      word_id = @db.select_rows("SELECT id FROM name_words WHERE word = #{data[0]}")[0][0]
      name_string_id = data[5]
      semantic_meaning_id = data[6]
      word_pos = data[3]
      length = data[4]
      [word_id, name_string_id, semantic_meaning_id, word_pos, length].join(",")
    end.join("),(")
    @db.execute("INSERT INTO name_word_semantic_meanings (name_word_id, name_string_id, semantic_meaning_id, position, length) VALUES (#{insert_semantic_words})")
  end

  def tarball_path
    Rails.root.join('tmp', id.to_s).to_s
  end

  def record_to_index(name_string, record)
    canonical_name = record.pop
    record = record.map  do |r|
      @db.quote(r)
    end
    record << canonical_name
    @index[name_string] ? @index[name_string] << record : @index[name_string] = [record]
  end

  def process_canonical_form(data)
    ids = data.map { |d| d[0] }.join(",")
    q = "SELECT id, canonical_form FROM parsed_name_strings WHERE id IN (#{ids}) AND canonical_form IS NOT NULL"
    res = @db.select_rows(q)
    insert_canonical_forms = res.map do |id, canonical_form|
        len = canonical_form.size
        first_letter = canonical_form[0] != "×" ? canonical_form[0] : canonical_form.gsub(/^×\s*/,'')[0]
        "'%s','%s', %s" % [canonical_form, first_letter, len]
    end.join("),(")
    if insert_canonical_forms.size > 0
      @db.execute("INSERT IGNORE INTO canonical_forms (name, first_letter, length) VALUES (#{insert_canonical_forms})")
      @db.execute("CREATE TEMPORARY TABLE tmp_name_string_canonical  (SELECT pns.id AS id, cf.id AS canonical_form_id FROM parsed_name_strings pns JOIN canonical_forms cf ON cf.name = pns.canonical_form WHERE pns.id in (#{ids}))")
      @db.execute("UPDATE name_strings ns JOIN tmp_name_string_canonical tnsc ON ns.id = tnsc.id SET ns.canonical_form_id = tnsc.canonical_form_id")
      #TODO will indexing of the temp table help in any way?
      @db.execute("DROP TEMPORARY TABLE tmp_name_string_canonical")
    end
  end

  def store_index
    DarwinCore.logger_write(@dwc.object_id, "Inserting indices")
    @db.execute("DROP TEMPORARY TABLE IF EXISTS `tmp_name_string_indices`")
    @db.execute("DROP TEMPORARY TABLE IF EXISTS `tmp_vernacular_string_indices`")
    @db.execute("CREATE TEMPORARY TABLE `tmp_name_string_indices` LIKE `name_string_indices`")
    @db.execute("CREATE TEMPORARY TABLE `tmp_vernacular_string_indices` LIKE `vernacular_string_indices`")
    count = 0
    @data.keys.in_groups_of(NAME_BATCH_SIZE) do |group|
      count += NAME_BATCH_SIZE
      names_index = []
      vernacular_index = []
      group.compact.each do |key|
        now = @db.quote(time_string)
        taxon = @data[key]
        name_string_id = @db.quote(get_name_string_id(taxon.current_name))
        taxon_id = @db.quote(key)
        rank = taxon.rank.blank? ? "NULL" : @db.quote(taxon.rank)
        source = taxon.source.blank? ? "NULL" : @db.quote(taxon.source)
        classification_path_id =  taxon.classification_path_id.compact
        classification_path = "''"
        unless classification_path_id.blank?
          classification_path = @db.quote(get_classification_path(taxon))
        end
        classification_path_id = @db.quote(classification_path_id.join("|"))
        if name_string_id != "NULL"
          names_index << [data_source_id, name_string_id, taxon_id, source, rank, taxon_id, "NULL", classification_path, classification_path_id, now, now].join(",")
        else
          puts "*" * 80
          puts "Taxon with id %s was not created" % key
        end
        taxon.synonyms.each do |synonym|
          count += 1
          synonym_string_id = @db.quote(get_name_string_id(synonym.name))
          synonym_taxon_id = synonym.id ? synonym.id : taxon_id
          synonym_source = synonym.source.blank? ? source : @db.quote(synonym.source)
          synonym_taxon_id = @db.quote(synonym_taxon_id)
          if synonym_string_id != "NULL"
            names_index << [data_source_id, synonym_string_id, synonym_taxon_id, synonym_source, rank, taxon_id, "'synonym'", classification_path, classification_path_id, now, now].join(",")
          end
        end
        taxon.vernacular_names.each do |vernacular|
          count += 1
          vernacular_string_id = @db.quote(get_name_string_id(vernacular.name, true))
          language = @db.quote(vernacular.language)
          locality = @db.quote(vernacular.locality)
          country_code = @db.quote(vernacular.country_code)
          if vernacular_string_id != "NULL"
            vernacular_index << [data_source_id, vernacular_string_id, taxon_id, language, locality, country_code, now, now].join(",")
          end
        end
      end
      names_index = names_index.join("),(")
      vernacular_index = vernacular_index.join("),(")
      if names_index.size > 0
        q = "INSERT IGNORE INTO tmp_name_string_indices (data_source_id, name_string_id, taxon_id, url, rank, accepted_taxon_id, synonym, classification_path, classification_path_ids, created_at, updated_at) VALUES (#{names_index})"
        @db.execute(q)
      end
      if vernacular_index.size > 0
        @db.execute("INSERT IGNORE INTO tmp_vernacular_string_indices (data_source_id, vernacular_string_id, taxon_id, language, locality, country_code, created_at, updated_at) VALUES (#{vernacular_index})")
      end
      DarwinCore.logger_write(@dwc.object_id, "Processed %s indices" % count)
    end
  end

  def publish_new_data
    DarwinCore.logger_write(@dwc.object_id, "Making new data available")
    @db.transaction do
      @db.execute("DELETE FROM name_string_indices WHERE data_source_id = #{data_source_id}")
      @db.execute("DELETE FROM vernacular_string_indices WHERE data_source_id = #{data_source_id}")
      @db.execute("INSERT INTO name_string_indices (SELECT * FROM tmp_name_string_indices)")
      @db.execute("INSERT INTO vernacular_string_indices (SELECT * FROM tmp_vernacular_string_indices)")
      @db.execute("DROP TEMPORARY TABLE tmp_name_string_indices")
      @db.execute("DROP TEMPORARY TABLE tmp_vernacular_string_indices")
    end
    DarwinCore.logger_write(@dwc.object_id, "Import finished")
  end

  def get_name_string_id(name_string, vernacular = false)
    return nil if name_string.blank? # bad dwca record, we are salvaging synonyms here
    table_name = vernacular ? "vernacular_strings" : "name_strings"
    string_hash = vernacular ? @vernacular_strings : @name_strings
    begin
    unless string_hash[name_string][:id]
      res = @db.select_rows("SELECT id FROM %s WHERE name = %s" % [table_name, string_hash[name_string][:normalized]])[0][0]
      string_hash[name_string][:id] = res.blank? ? nil : res[0][0]
    end
    rescue
      string_hash[name_string][:id] = nil
    end
    string_hash[name_string][:id]
  end

  def get_classification_path(taxon)
    taxon.classification_path_id.compact.map do |key|
      if @data[key].current_name_canonical # reuse canonica data if exists
        @data[key].current_name_canonical
      else
        name_string = @db.quote(NameString.normalize_space(@data[key].current_name))
        res = @db.select_rows("SELECT cf.name FROM name_strings ns JOIN canonical_forms cf ON ns.canonical_form_id = cf.id WHERE ns.name = #{name_string}")[0]
        @data[key].current_name_canonical = res.blank? ? '' : res[0]
      end
    end.join("|")
  end

  def time_string
    @db.select_rows("SELECT NOW()")[0][0]
  end

  def get_uuid(name)
    UUID.create_v5(name, Gni::Config.uuid_namespace).to_i
  end
end
