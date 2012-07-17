# encoding: utf-8
class ParsedNameString < ActiveRecord::Base
  has_one :name_string

  def self.reparse
    #TODO implement reparsing
  end

  def self.update(opts = {})
    #TODO implement reparsing for newer parser versions
    opts = {:update_outdated => false, :logger_object_id => 0}.merge(opts)
    Gni.logger_write(opts[:logger_object_id], "Parsing incoming strings")
    parser_version_int = Gni.version_to_int(ScientificNameParser::VERSION)
    count = 0
    NameString.transaction do
      while true do
        now = self.time_string
        q = "SELECT id, name FROM name_strings WHERE has_words IS NULL LIMIT %s" % Gni::Config.batch_size
        parser = ScientificNameParser.new
        res = self.connection.select_rows(q)
        set_size = res.size
        break if set_size == 0
        ids = []
        names = []
        res = res.map { |id, name| [id, (parser.parse(name) rescue self.parser_error(name))] }
        words = []
        sql_data = res.map do |id, data|
          parsed = data[:scientificName][:parsed] ? 1 : 0
          self.collect_words(words, id, data) if parsed == 1
          parser_run = data[:scientificName][:parser_run].to_i
          parser_version = data[:scientificName][:parser_version]
          canonical = parsed == 1 ? self.connection.quote(data[:scientificName][:canonical]) : "NULL"
          dump_data = self.connection.quote(data.to_json)
          "%s, %s, '%s', %s, %s, %s, '%s', '%s'" % [id, parsed, parser_version, parser_run, canonical, dump_data, now, now]
        end.join("),(")
        self.connection.execute("INSERT IGNORE INTO parsed_name_strings (id, parsed, parser_version, pass_num, canonical_form, data, created_at, updated_at) VALUES (%s)" % sql_data)
        self.connection.execute("UPDATE name_strings SET has_words = 1, parser_version = #{parser_version_int} WHERE id IN (#{res.map{|i| i[0]}.join(",")})")
        self.insert_words(words) if words.size > 0
        self.process_canonical_form(res)
        count += set_size
        Gni.logger_write(opts[:logger_object_id], "Parsed %s names" % count)
      end
    end
  end
  
  def self.parser_error(name)
    { scientificName: { parsed: false, verbatim: name,  error: 'Parser error', parser_run: 0 } }
  end
  
  def self.collect_words(words, name_string_id, parsed_data)
    name_string = parsed_data[:scientificName][:verbatim]
    pos = parsed_data[:scientificName][:positions]
    pos.keys.each do |key|
      word_start = key.to_i
      word_end = pos[key][1]
      length = word_end - word_start
      word = Taxamatch::Normalizer.normalize_word(name_string[word_start..word_end])
      word_type = SemanticMeaning.send(pos[key][0]).id
      first_letter = word[0] ? word[0] : ""
      words << [self.connection.quote(word), "'" + first_letter + "'", word.size, word_start, length, name_string_id, word_type]
    end
  end

  def self.insert_words(words)
    insert_words = words.map { |w| w[0..2].join(",") }.join("),(")
    self.connection.execute("INSERT IGNORE INTO name_words (word, first_letter, length) VALUES (#{insert_words})")
    insert_semantic_words = words.map do |data|
      word_id = self.connection.select_rows("SELECT id FROM name_words WHERE word = #{data[0]}")[0][0]
      name_string_id = data[5]
      semantic_meaning_id = data[6]
      word_pos = data[3]
      length = data[4]
      [word_id, name_string_id, semantic_meaning_id, word_pos, length].join(",")
    end.join("),(")
    self.connection.execute("INSERT INTO name_word_semantic_meanings (name_word_id, name_string_id, semantic_meaning_id, position, length) VALUES (#{insert_semantic_words})")
  end
  
  def self.process_canonical_form(data)
    time_string = self.time_string
    ids = data.map { |d| d[0] }.join(",")
    q = "SELECT id, canonical_form FROM parsed_name_strings WHERE id IN (#{ids}) AND canonical_form IS NOT NULL"
    res = self.connection.select_rows(q)
    insert_canonical_forms = res.map do |id, canonical_form|
        len = canonical_form.size
        first_letter = canonical_form[0] != "×" ? canonical_form[0] : canonical_form.gsub(/^×\s*/,'')[0]
        "'%s','%s', %s, '%s', '%s'" % [canonical_form, first_letter, len, time_string, time_string]
    end.join("),(")
    if insert_canonical_forms.size > 0
      self.connection.execute("INSERT IGNORE INTO canonical_forms (name, first_letter, length, created_at, updated_at) VALUES (#{insert_canonical_forms})")
      self.connection.execute("CREATE TEMPORARY TABLE tmp_name_string_canonical  (SELECT pns.id AS id, cf.id AS canonical_form_id FROM parsed_name_strings pns JOIN canonical_forms cf ON cf.name = pns.canonical_form WHERE pns.id in (#{ids}))")
      self.connection.execute("UPDATE name_strings ns JOIN tmp_name_string_canonical tnsc ON ns.id = tnsc.id SET ns.canonical_form_id = tnsc.canonical_form_id")
      #TODO will indexing of the temp table help in any way?
      self.connection.execute("DROP TEMPORARY TABLE tmp_name_string_canonical")
    end
  end

  def self.time_string
    self.connection.select_rows("SELECT NOW()")[0][0]
  end


end
