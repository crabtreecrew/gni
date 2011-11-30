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

  def import
    begin
      fetch_tarball
      read_tarball
      store_name_strings
      store_vernacular_name_strings
      parse_canonicals
      # build_index
      # process_records
      # update_canonical_form_ids
      true
    rescue RuntimeError => e
      DarwinCore.logger_write(@dwc.object_id, "Import Failed: %s" % e)
      false
    end
  end

  private

  def update_canonical_form_ids
    DarwinCore.logger_write(@dwc.object_id, "Adding information about canonical forms of name_strings")
    @update_canonical_list.each_with_index do |data, i|
      name_string_id, canonical_form_id = data
      DarwinCore.logger_write(@dwc.object_id, "Added canonical forms info to %s name" % i) if i % NAME_BATCH_SIZE == 0 && i != 0
      NameString.connection.execute("update name_strings set canonical_form_id = %s where id = %s" % [canonical_form_id, name_string_id])
    end
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
    @dwc               = DarwinCore.new(tarball_path)
    DarwinCore.logger.subscribe(:an_object_id => @dwc.object_id, :job_id => self.id, :type => 'DwcaImporterLog')
    normalizer        = DarwinCore::ClassificationNormalizer.new(@dwc)
    @data = normalizer.normalize(:with_canonical_names => false);
    @tree             = normalizer.tree
    @name_strings     = normalizer.name_strings
    @vernacular_name_strings = normalizer.vernacular_name_strings
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
        name_string = NameString.connection.quote(NameString.normalize(name_string)).force_encoding('utf-8')
        normalized = Taxamatch::Normalizer.normalize(name_string);
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
        name_string = NameString.connection.quote(NameString.normalize(name_string)).force_encoding('utf-8')
        "%s, '%s','%s'" % [name_string, now, now]
      end.join('), (')
      NameString.connection.execute "INSERT IGNORE INTO vernacular_strings (name, created_at, updated_at) VALUES (#{group})"
      DarwinCore.logger_write(@dwc.object_id, "Traversed %s vernacular name strings" % count)
    end
  end

  def parse_canonicals
    DarwinCore.logger_write(@dwc.object_id, "Parsing incomding strings")
    parser = ScientificNameParser.new
    count = 0
    while true do
      q = "select id, name from name_strings where has_words is null limit %s" % NAME_BATCH_SIZE
      res = NameString.connection.select_rows(q)
      set_size = res.size
      break if set_size == 0
      ids = []
      names = []
      res = res.map { |id, name| [id, parser.parse(name)] }

      sql_data = res.map do |id, data|
        parsed = data[:scientificName][:parsed] ? 1 : 0
        insert_words(id, data) if parsed == 1
        parser_run = data[:scientificName][:parser_run]
        parser_version = data[:scientificName][:parser_version]
        canonical = parsed == 1 ? NameString.connection.quote(data[:scientificName][:canonical]) : "NULL"
        dump_data = NameString.connection.quote(Marshal.dump(data))
        "%s, %s, '%s', %s, %s, %s" % [id, parsed, parser_version, parser_run, canonical, dump_data]
      end.join("),(")

      NameString.connection.execute("insert ignore into parsed_name_strings (id, parsed, parser_version, pass_num, canonical_form, data) values (%s)" % sql_data)
      NameString.connection.execute("update name_strings set has_words = 1 where id in (#{res.map{|i| i[0]}.join(",")})")
      count += set_size
      DarwinCore.logger_write(@dwc.object_id, "Parsed %s name" % count)
    end
  end

  def insert_words(name_string_id, parsed_data)
    words = {}
    require 'ruby-debug'; debugger
    puts ''
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

  def process_canonical_form(name_string_id, canonical_name)
    if canonical_name && !canonical_name.empty?
      canonical_name_sql = NameString.connection.quote(canonical_name)
      canonical_name_id, cf_name_string_id = NameString.connection.select_rows("
        select cf.id, ns.id
        from canonical_forms cf
          right outer join name_strings ns on ns.id = cf.name_string_id
        where ns.name = %s" % canonical_name_sql)[0]
      unless canonical_name_id
        len = canonical_name.size
        first_letter = canonical_name[0] != "×" ? canonical_name[0] : canonical_name.gsub(/^×\s*/,'')[0]
        NameString.connection.execute("
            insert into canonical_forms
            (name_string_id, first_letter, length)
            values
            (%s, '%s', %s)" % [cf_name_string_id, first_letter, len])
        canonical_name_id = NameString.connection.select_rows("select last_insert_id()")[0][0]
        @update_canonical_list[name_string_id] = canonical_name_id
      end
    end
  end

  def build_index
    @index = {}
    @data.keys.each_with_index do |k, i|
      t = @data[k]
      now = time_string
      DarwinCore.logger_write(@dwc.object_id, "Preparing %s index record" % i) if i % 10000 == 0 && i != 0
      t.classification_path.each do |path|
        name_string = NameString.connection.quote(NameString.normalize(@data[k].current_name))
        record = [t.id, nil, nil, t.rank, nil, nil, nil, nil, nil, t.classification_path.join("|"), t.classification_path_id.join("|"), now, now, t.current_name_canonical]
        record_to_index(name_string, record)
        t.synonyms.each do |s|
          name_string = NameString.connection.quote(NameString.normalize(s.name))
          record = [s.id, nil, nil, t.rank, t.id, 'synonym', nil, nil, nil, t.classification_path.join("|"), t.classification_path_id.join("|"), now, now, s.canonical_name]
          record_to_index(name_string, record)
        end
        t.vernacular_names.each do |v|
          name_string = NameString.connection.quote(NameString.normalize(v.name))
          record = [nil, nil, nil, t.rank, t.id, nil, 1, v.language, v.locality, t.classification_path.join("|"), t.classification_path_id.join("|"), now, now, nil]
          record_to_index(name_string, record)
        end
      end
    end
  end

  def process_records
    records = []
    @index.keys.each_with_index do |name_string, i|
      DarwinCore.logger_write(@dwc.object_id, "Inserting %s index" % i) if i % 10000 == 0 && i != 0
      name_string_id = NameString.connection.select_rows("select id from name_strings where name = %s" % name_string)[0][0]
      NameString.connection.execute "INSERT INTO name_string_indices (name_string_id, data_source_id, created_at, updated_at) VALUES (%s, %s, now(), now())" % [name_string_id, data_source_id]
      idx_id = NameString.connection.select_rows("select last_insert_id()")[0][0]
      rows = @index.delete(name_string)
      rows = rows.map do |row|
        process_canonical_form(name_string_id, row.pop)
        row << idx_id
        row.join(",")
      end
      rows.size == 1 ? records << rows[0] : records += rows
    end
    count = 0
    records.in_groups_of(NAME_BATCH_SIZE).each do |group|
      count += NAME_BATCH_SIZE
      DarwinCore.logger_write(@dwc.object_id, "Inserting %s index record" % count)
      group = group.compact.join('), (')
      q = "INSERT INTO name_string_index_records
        (taxon_id, global_id, url, rank, accepted_taxon_id,
        synonym, vernacular, language, locality,
        classification_path, classification_path_ids,
        created_at, updated_at, name_index_id)
        VALUES (#{group})"
      NameString.connection.execute q
    end
  end

  def time_string
    NameString.connection.select_rows("select now()")[0][0]
  end
end
