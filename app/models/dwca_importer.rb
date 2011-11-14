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
      store_data
      # activate_tree
      true
    rescue RuntimeError => e
      DarwinCore.logger_write(@dwc.object_id, "Import Failed: %s" % e)
      false
    end
  end

  def fetch_tarball
    if url.match(/^\s*http:\/\//)
      dlr = Gni::Downloader.new(url, tarball_path)
      downloaded_length = dlr.download_with_percentage do |r|
        msg = sprintf("Downloaded %.0f%% in %.0f seconds ETA is %.0f seconds", r[:percentage], r[:elapsed_time], r[:eta])
        JobLog.create(:job_type => "DwcaImporter", :job_id => self.id, :message => msg)
      end
      JobLog.create(:job_type => "DwcaImporter", :job_id => self.id, :message => "Download finished, Size: %s" % downloaded_length)
    else
      Kernel.system("curl -s #{url} > #{tarball_path}")
    end
  end

  def read_tarball
    @dwc               = DarwinCore.new(tarball_path)
    DarwinCore.logger.subscribe(:an_object_id => @dwc.object_id, :job_id => self.id, :job_type => 'DwcaImporter')
    normalizer        = DarwinCore::ClassificationNormalizer.new(@dwc)
    @data = normalizer.normalize
    @tree             = normalizer.tree
    @name_strings     = normalizer.name_strings
    @languages        = {}
    @record_count     = 0
  end

  def store_data
    DarwinCore.logger_write(@dwc.object_id, "Populating local database")
    DarwinCore.logger_write(@dwc.object_id, "Processing name strings")
    count = 0
    @name_strings.in_groups_of(NAME_BATCH_SIZE).each do |group|
      count += NAME_BATCH_SIZE
      now = time_string 
      group = group.compact.map do |name_string|
        name_string = NameString.connection.quote(NameString.normalize(name_string)).force_encoding('utf-8')
        "%s,'%s','%s'" % [name_string, now, now] 
      end.join('), (')
      NameString.connection.execute "INSERT IGNORE INTO name_strings (name, created_at, updated_at) VALUES (#{group})"
      DarwinCore.logger_write(@dwc.object_id, "Traversed %s scientific name strings" % count)
    end
    build_index
    # DarwinCore.logger_write(@dwc.object_id, "Adding synonyms and vernacular names")
    # insert_synonyms_and_vernacular_names
  end
  private

  def tarball_path
    Rails.root.join('tmp', id.to_s).to_s
  end

  def build_index
    @index = {}
    @data.keys.each_with_index do |k, i|
      t = @data[k]
      now = time_string
      DarwinCore.logger_write(@dwc.object_id, "Preparing %s index record" % i) if i % 10000 == 0 && i != 0

      name_string = NameString.connection.quote(NameString.normalize(@data[k].current_name))
      record = [t.id, nil, nil, t.rank, nil, nil, nil, nil, nil, t.classification_path.join("|"), t.classification_path_id.join("|"), now, now].map  do |r| 
        NameString.connection.quote(r)
      end
      @index[name_string] ? @index[name_string] << record : @index[name_string] = [record] 
      t.synonyms.each do |s|
        name_string = NameString.connection.quote(NameString.normalize(s.name))
        record = [s.id, nil, nil, t.rank, t.id, 'synonym', nil, nil, nil, t.classification_path.join("|"), t.classification_path_id.join("|"), now, now].map do |r|
          NameString.connection.quote(r)
        end
        @index[name_string] ? @index[name_string] << record : @index[name_string] = [record] 
      end
      t.vernacular_names.each do |v|
        name_string = NameString.connection.quote(NameString.normalize(v.name))
        record = [nil, nil, nil, t.rank, t.id, nil, 1, v.language, v.locality, t.classification_path.join("|"), t.classification_path_id.join("|"), now, now].map do |r|
          NameString.connection.quote(r)
        end
        @index[name_string] ? @index[name_string] << record : @index[name_string] = [record] 
      end
    end
    records = []
    @index.keys.each_with_index do |name_string, i|
      DarwinCore.logger_write(@dwc.object_id, "Inserting %s index" % i) if i % 10000 == 0 && i != 0
      name_string_id = NameString.connection.select_rows("select id from name_strings where name = %s" % name_string)[0][0]
      NameString.connection.execute "INSERT INTO name_string_indices (name_string_id, data_source_id, created_at, updated_at) VALUES (%s, %s, now(), now())" % [name_string_id, data_source_id]
      idx_id = NameString.connection.select_rows("select last_insert_id()")[0][0]
      rows = @index.delete(name_string) 
      rows = rows.map do |row| 
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
      q = "INSERT IGNORE INTO name_string_index_records 
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
