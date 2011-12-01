# encoding: utf-8
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
    now = Time.now()
    begin
      fetch_tarball
        now = get_time(now)
      read_tarball
        now = get_time(now)
      store_name_strings
        now = get_time(now)
      store_vernacular_name_strings
        now = get_time(now)
      parse_name_strings
        now = get_time(now)
      store_index
        now = get_time(now)
      true
    rescue RuntimeError => e
      DarwinCore.logger_write(@dwc.object_id, "Import Failed: %s" % e)
      false
    end
  end

  private

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
    @dwc               = DarwinCore.new(tarball_path)
    DarwinCore.logger.subscribe(:an_object_id => @dwc.object_id, :job_id => self.id, :type => 'DwcaImporterLog')
    normalizer        = DarwinCore::ClassificationNormalizer.new(@dwc)
    @data = normalizer.normalize(:with_canonical_names => false);
    @tree             = normalizer.tree
    @name_strings     = normalizer.name_strings
    @name_string_hash = {}
    @vernacular_name_strings = normalizer.vernacular_name_strings
    @vernacular_name_hash = {}
    @languages        = {}
    @record_count     = 0
    @update_canonical_list = {}
  end

  def store_name_strings
    DarwinCore.logger_write(@dwc.object_id, "Populating local database")
    DarwinCore.logger_write(@dwc.object_id, "Processing scientific name strings")
    count = 0
    @name_strings.in_groups_of(NAME_BATCH_SIZE).each do |group|
      count += NAME_BATCH_SIZE
      now = time_string
      group = group.compact.map do |name_string|
        @name_string_hash[name_string] = {normalized: NameString.connection.quote(NameString.normalize(name_string)).force_encoding('utf-8')}
        normalized = Taxamatch::Normalizer.normalize(@name_string_hash[name_string][:normalized]);
        "%s, %s, '%s','%s'" % [name_string, normalized, now, now]
      end.join('), (')
      NameString.connection.execute "INSERT IGNORE INTO name_strings (name, normalized, created_at, updated_at) VALUES (#{group})"
      DarwinCore.logger_write(@dwc.object_id, "Traversed %s scientific name strings" % count)
    end
  end

  def store_vernacular_name_strings
    DarwinCore.logger_write(@dwc.object_id, "Processing vernacular name strings")
    count = 0
    @vernacular_name_strings.in_groups_of(NAME_BATCH_SIZE).each do |group|
      count += NAME_BATCH_SIZE
      now = time_string
      group = group.compact.map do |name_string|
        @vernacular_string_hash[name_string] = {normalized: NameString.connection.quote(NameString.normalize(name_string)).force_encoding('utf-8')}
        "%s, '%s','%s'" % [name_string, now, now]
      end.join('), (')
      NameString.connection.execute "INSERT IGNORE INTO vernacular_strings (name, created_at, updated_at) VALUES (#{group})"
      DarwinCore.logger_write(@dwc.object_id, "Traversed %s vernacular name strings" % count)
    end
  end

  def parse_name_strings
    DarwinCore.logger_write(@dwc.object_id, "Parsing incoming strings")
    count = 0
    while true do
      now = time_string
      q = "select id, name from name_strings where has_words is null limit %s" % NAME_BATCH_SIZE
      parser = ScientificNameParser.new
      res = NameString.connection.select_rows(q)
      set_size = res.size
      break if set_size == 0
      ids = []
      names = []
      res = res.map { |id, name| [id, parser.parse(name)] }
      words = []
      sql_data = res.map do |id, data|
        parsed = data[:scientificName][:parsed] ? 1 : 0
        collect_words(words, id, data) if parsed == 1
        parser_run = data[:scientificName][:parser_run]
        parser_version = data[:scientificName][:parser_version]
        canonical = parsed == 1 ? NameString.connection.quote(data[:scientificName][:canonical]) : "NULL"
        dump_data = NameString.connection.quote(Marshal.dump(data))
        "%s, %s, '%s', %s, %s, %s, '%s', '%s'" % [id, parsed, parser_version, parser_run, canonical, dump_data, now, now]
      end.join("),(")
      NameString.connection.execute("insert ignore into parsed_name_strings (id, parsed, parser_version, pass_num, canonical_form, data, created_at, updated_at) values (%s)" % sql_data)
      NameString.connection.execute("update name_strings set has_words = 1 where id in (#{res.map{|i| i[0]}.join(",")})")
      insert_words(words)
      process_canonical_form(res)
      count += set_size
      DarwinCore.logger_write(@dwc.object_id, "Parsed %s name" % count)
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
      words << [NameString.connection.quote(word), "'" + word[0] + "'", word.size, word_start, length, name_string_id, word_type] 
    end
  end

  def insert_words(words)
    insert_words = words.map { |w| w[0..2].join(",") }.join("),(")
    NameString.connection.execute("insert ignore into name_words (word, first_letter, length) values (#{insert_words})") 
    insert_semantic_words = words.map do |data|
      word_id = NameString.connection.select_rows("select id from name_words where word = #{data[0]}")[0][0]
      name_string_id = data[5]
      semantic_meaning_id = data[6]
      word_pos = data[3]
      length = data[4]
      [word_id, name_string_id, semantic_meaning_id, word_pos, length].join(",")
    end.join("),(")
    NameString.connection.execute("insert into name_word_semantic_meanings (name_word_id, name_string_id, semantic_meaning_id, position, length) values (#{insert_semantic_words})")
  end

  def tarball_path
    Rails.root.join('tmp', id.to_s).to_s
  end

  def record_to_index(name_string, record)
    canonical_name = record.pop
    record = record.map  do |r|
      NameString.connection.quote(r)
    end
    record << canonical_name
    @index[name_string] ? @index[name_string] << record : @index[name_string] = [record]
  end

  def process_canonical_form(data)
    ids = data.map { |d| d[0] }.join(",")
    q = "select id, canonical_form from parsed_name_strings where id in (#{ids}) and canonical_form is not null"
    res = NameString.connection.select_rows(q)
    insert_canonical_forms = res.map do |id, canonical_form|
        len = canonical_form.size
        first_letter = canonical_form[0] != "×" ? canonical_form[0] : canonical_form.gsub(/^×\s*/,'')[0]
        "'%s','%s', %s" % [canonical_form, first_letter, len]
    end.join("),(")
    NameString.connection.execute(" insert ignore into canonical_forms (name, first_letter, length) values (#{insert_canonical_forms})")
    NameString.connection.execute("create temporary table tmp_name_string_canonical  (select pns.id as id, cf.id as canonical_form_id from parsed_name_strings pns join canonical_forms cf on cf.name = pns.canonical_form where pns.id in (#{ids}))")
    NameString.connection.execute("update name_strings ns join tmp_name_string_canonical tnsc on ns.id = tnsc.id set ns.canonical_form_id = tnsc.canonical_form_id")
    #TODO will indexing of the temp table help in any way?
    NameString.connection.execute("drop temporary table tmp_name_string_canonical")
  end

  def store_index
    c = NameString.connection
    count = 0
    @data.keys.in_groups_of(NAME_BATCH_SIZE) do |group|
      count += NAME_BATCH_SIZE
      names_index = []
      vernacular_index = []
      group.each do |key|
        taxon = @data[key]
        name_string_id = get_name_string_id(taxon.current_name)
        taxon_id = c.quote(key)
        rank = taxon.rank ? c.quote(taxon) : "NULL"
        classification_path = c.quote(get_classification_path(taxon))
        classification_path_id = c.quote(taxon.classification_path_id.join("|"))
        names_index << [data_source_id, name_string_id, taxon_id, rank, "NULL", "NULL", classification_path, classification_path_id].join(",") 
        taxon.synonyms.each do |synonym|
          synonym_string_id = get_name_string_id(synonym.name)
          names_index << [data_source_id, synonym_string_id, taxon_id, rank, name_string_id, "'synonym'", classification_path, classification_path_id].join(",")
        end
        taxon.vernacular_names.each do |vernacular|
          vernacular_string_id = get_name_string_id(vernacular.name, true)
          language = c.quote(vernacular.language)
          locality = c.quote(vernacular.locality)
          vernacular_index << [data_source_id, vernacular_string_id, taxon_id, language, locality].join(",")
        end
      end
      names_index = names_index.join("),(")
      vernacular_index = vernacular_index.join("),(")
      c.transaction do
        c.execute("delete from name_string_indices where data_source_id = #{data_source_id}")
        c.execute("insert into name_string_indices (data_source_id, name_string_id, taxon_id, accepted_taxon_id, synonym, classification_path, classification_path_id) values (#{names_index})")
      end
      c.transaction do
        c.execute("delete from vernacular_string_indices where data_source_id = #{data_source_id}")
        c.execute("insert into vernacular_string_indices (data_source_id, vernacular_string_id, taxon_id, language, locality) values (#{vernacular_index})"
      end
    end
  end

  def get_name_string_id(name_string, verncaular = false)
    table_name = vernacular ? "vernacular_strings" : "name_strings"
    string_hash = vernacular ? @vernacular_string_hash : @name_string_hash
    unless string_hash[name_string][:id]
      string_hash[name_string][:id] = NameString.connection.select_rows("select id from %s where name = %s" % [table_name, string_hash[name_string][:normalized]])[0][0]
    end
    string_hash[name_string][:id]
  end

  def get_classification_path(taxon)
    taxon.classification_path_id.map do |key|
      if @data[key].canonical_name
        @data[key].canonical_name
      else
        name_string = NameString.connection.quote(NameString.normalize(taxon.current_name))
        @data[key].canonical_name = NameString.connection.select_rows("select cf.name from name_strings ns join canonical_forms cf on ns.canonical_form_id = canonical_form.id where ns.name = #{name_string}")[0][0]
      end
    end.join("|")
  end
  
  def time_string
    NameString.connection.select_rows("select now()")[0][0]
  end
end
