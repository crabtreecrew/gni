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
      publish_new_data
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
    @vernacular_string_hash = {}
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
        tm_normalized = Taxamatch::Normalizer.normalize(@name_string_hash[name_string][:normalized]);
        "%s, %s, '%s','%s'" % [@name_string_hash[name_string][:normalized], tm_normalized, now, now]
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
        "%s, '%s','%s'" % [@vernacular_string_hash[name_string][:normalized], now, now]
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
      q = "select id, name from name_strings where has_words is null limit %s" % 1000
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
        parser_run = data[:scientificName][:parser_run].to_i
        parser_version = data[:scientificName][:parser_version]
        canonical = parsed == 1 ? NameString.connection.quote(data[:scientificName][:canonical]) : "NULL"
        dump_data = NameString.connection.quote(data.to_json)
        "%s, %s, '%s', %s, %s, %s, '%s', '%s'" % [id, parsed, parser_version, parser_run, canonical, dump_data, now, now]
      end.join("),(")
      NameString.connection.execute("INSERT IGNORE INTO parsed_name_strings (id, parsed, parser_version, pass_num, canonical_form, data, created_at, updated_at) VALUES (%s)" % sql_data)
      NameString.connection.execute("UPDATE name_strings SET has_words = 1 WHERE id IN (#{res.map{|i| i[0]}.join(",")})")
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
      words << [NameString.connection.quote(word), "'" + first_letter + "'", word.size, word_start, length, name_string_id, word_type] 
    end
  end

  def insert_words(words)
    insert_words = words.map { |w| w[0..2].join(",") }.join("),(")
    NameString.connection.execute("INSERT IGNORE INTO name_words (word, first_letter, length) VALUES (#{insert_words})") 
    insert_semantic_words = words.map do |data|
      word_id = NameString.connection.select_rows("select id from name_words where word = #{data[0]}")[0][0]
      name_string_id = data[5]
      semantic_meaning_id = data[6]
      word_pos = data[3]
      length = data[4]
      [word_id, name_string_id, semantic_meaning_id, word_pos, length].join(",")
    end.join("),(")
    NameString.connection.execute("INSERT INTO name_word_semantic_meanings (name_word_id, name_string_id, semantic_meaning_id, position, length) VALUES (#{insert_semantic_words})")
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
    if insert_canonical_forms.size > 0
      NameString.connection.execute("INSERT IGNORE INTO canonical_forms (name, first_letter, length) VALUES (#{insert_canonical_forms})")
      NameString.connection.execute("create temporary table tmp_name_string_canonical  (select pns.id as id, cf.id as canonical_form_id from parsed_name_strings pns join canonical_forms cf on cf.name = pns.canonical_form where pns.id in (#{ids}))")
      NameString.connection.execute("update name_strings ns join tmp_name_string_canonical tnsc on ns.id = tnsc.id set ns.canonical_form_id = tnsc.canonical_form_id")
      #TODO will indexing of the temp table help in any way?
      NameString.connection.execute("drop temporary table tmp_name_string_canonical")
    end
  end

  def store_index
    DarwinCore.logger_write(@dwc.object_id, "Inserting indices")
    c = NameString.connection
    c.execute("DROP TEMPORARY TABLE IF EXISTS `tmp_name_string_indices`")
    c.execute("DROP TEMPORARY TABLE IF EXISTS `tmp_vernacular_string_indices`")
    c.execute("CREATE TEMPORARY TABLE `tmp_name_string_indices` LIKE `name_string_indices`")
    c.execute("CREATE TEMPORARY TABLE `tmp_vernacular_string_indices` LIKE `vernacular_string_indices`")
    count = 0
    @data.keys.in_groups_of(NAME_BATCH_SIZE) do |group|
      count += NAME_BATCH_SIZE
      names_index = []
      vernacular_index = []
      group.compact.each do |key|
        now = c.quote(time_string)
        taxon = @data[key]
        name_string_id = get_name_string_id(taxon.current_name)
        taxon_id = c.quote(key)
        rank = taxon.rank.blank? ? "NULL" : c.quote(taxon.rank)
        classification_path_id =  taxon.classification_path_id.compact
        classification_path = "''"
        if classification_path_id.blank?
          classification_path_id = "''"
        else
          classification_path = c.quote(get_classification_path(taxon))
          classification_path_id = c.quote(classification_path_id.join("|").force_encoding("utf-8"))
        end
        if name_string_id != "NULL"
          begin
            names_index << [data_source_id, name_string_id, taxon_id, rank, "NULL", "NULL", classification_path, classification_path_id, now, now].join(",") 
          rescue Encoding::CompatibilityError
            require 'ruby-debug'; debugger
            puts ''
          end
        else
          puts "*" * 80
          puts taxon
          puts "*" * 80
        end
        taxon.synonyms.each do |synonym|
          count += 1
          synonym_string_id = get_name_string_id(synonym.name)
          synonym_taxon_id = synonym.id ? synonym.id : taxon_id
          if synonym_string_id != "NULL"
            names_index << [data_source_id, synonym_string_id, synonym_taxon_id, rank, name_string_id, "'synonym'", classification_path, classification_path_id, now, now].join(",")
          end
        end
        taxon.vernacular_names.each do |vernacular|
          count += 1
          vernacular_string_id = get_name_string_id(vernacular.name, true)
          language = c.quote(vernacular.language)
          locality = c.quote(vernacular.locality)
          if vernacular_string_id
            vernacular_index << [data_source_id, vernacular_string_id, taxon_id, language, locality, now, now].join(",")
          end
        end
      end
      names_index = names_index.join("),(")
      vernacular_index = vernacular_index.join("),(")
      if names_index.size > 0
        c.execute("insert into tmp_name_string_indices (data_source_id, name_string_id, taxon_id, rank, accepted_taxon_id, synonym, classification_path, classification_path_ids, created_at, updated_at) values (#{names_index})")
      end
      if vernacular_index.size > 0
        c.execute("insert into tmp_vernacular_string_indices (data_source_id, vernacular_string_id, taxon_id, language, locality, created_at, updated_at) values (#{vernacular_index})")
      end
      DarwinCore.logger_write(@dwc.object_id, "Processed %s indices" % count)
    end
  end

  def publish_new_data
    DarwinCore.logger_write(@dwc.object_id, "Making new data available")
    c = NameString.connection
    c.transaction do
      c.execute("delete from name_string_indices where data_source_id = #{data_source_id}")
      c.execute("delete from vernacular_string_indices where data_source_id = #{data_source_id}")
      c.execute("insert into name_string_indices (select * from tmp_name_string_indices)") 
      c.execute("insert into vernacular_string_indices (select * from tmp_vernacular_string_indices)")
      c.execute("drop temporary table tmp_name_string_indices")
      c.execute("drop temporary table tmp_vernacular_string_indices")
    end
    DarwinCore.logger_write(@dwc.object_id, "Import finished")
  end

  def get_name_string_id(name_string, vernacular = false)
    return "NULL" if name_string.blank? # bad dwca record, we are salvaging synonyms here
    table_name = vernacular ? "vernacular_strings" : "name_strings"
    string_hash = vernacular ? @vernacular_string_hash : @name_string_hash
    unless string_hash[name_string][:id]
      string_hash[name_string][:id] = NameString.connection.select_rows("select id from %s where name = %s" % [table_name, string_hash[name_string][:normalized]])[0][0]
    end
    string_hash[name_string][:id]
  end

  def get_classification_path(taxon)
    taxon.classification_path_id.compact.map do |key|
      if @data[key].current_name_canonical
        @data[key].current_name_canonical
      else
        name_string = NameString.connection.quote(NameString.normalize(taxon.current_name))
        res = NameString.connection.select_rows("select cf.name from name_strings ns join canonical_forms cf on ns.canonical_form_id = cf.id where ns.name = #{name_string}")[0]
        @data[key].current_name_canonical = res ? res : ''
      end
    end.join("|")
  end
  
  def time_string
    NameString.connection.select_rows("select now()")[0][0]
  end
end
