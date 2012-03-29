require 'iconv'
class NameResolver < ActiveRecord::Base
  @queue = :name_resolver
  attr :contexts
  belongs_to :progress_status

  serialize :data, Array
  serialize :options, Hash
  serialize :result, Hash

  before_create :add_default_options

  CONTEXT_THRESHOLD = 0.9
  EXACT_STRING = 1
  EXACT_CANONICAL = 2
  FUZZY_CANONICAL = 3
  MAX_NAME_STRING = 10_000
  MAX_DATA_SOURCES = 5
  NAME_TYPES = { 1 => "uninomial", 2 => "binomial", 3 => "trinomial" }
  MESSAGES = {
    :no_data_source => "No data sources found. Please provide from 1 to %s data source ids" % MAX_DATA_SOURCES,
    :too_many_data_sources => "Too many data sources. Please provide from 1 to %s data source ids" % MAX_DATA_SOURCES,
    :no_names => "No name strings found. Please provide from 1 to %s name strings" % MAX_NAME_STRING,
    :too_many_names => "Too many name strings. Please provide from 1 to %s name strings" % MAX_NAME_STRING,
    :success => "OK",
  }
  
  def self.perform(name_resolver_id)
    r = NameResolver.find(name_resolver_id)
    r.reconcile
  end

  # read data for cases where it is supplied in a file.
  def self.read_file(file_path)
    process_data(open(file_path))
  end

  def self.read_data(data)
    process_data(data)
  end

  def self.read_names(names, ids=[])
    data = []
    names.each_with_index do |name, index|
      if ids.empty?
        data << "%s" % name
      else
        data << "%s|%s" % [ids[index], name]
      end
    end
    read_data(data)
  end

  def reconcile
    begin
      prepare_variables
      find_exact
      find_canonical_exact
      find_canonical_fuzzy
      get_contexts if @with_context
      calculate_scores
      format_result
    rescue Gni::Error => e
      progress_status_id = result[:status] = ProgressStatus.failed.id
      progress_message = result[:message] = e.message
    end
    save!
  end

private
  def self.process_data(new_data)
    conv = Iconv.new('UTF-8', 'ISO-8859-1')
    new_data.inject([]) do |res, line|
      #for now we assume that non-utf8 charachters are in latin1, might need to add others
      line = conv.conv(line) unless line.valid_encoding?
      #skip the line if encoding is still wrong
      next unless line.valid_encoding?
      line = line.strip.gsub("\t", "|")
      fields = line.split("|")
      name = id = nil
      return res if fields.blank?
      if fields.size == 1
        name = fields[0].strip
      elsif fields.size > 1
        id = fields[0].strip
        name = fields[1].strip
      end
      res << { :id => id, :name_string => name }
      res
    end
  end

  def prepare_variables
    @atomizer = Taxamatch::Atomizer.new
    @taxamatch = Taxamatch::Base.new
    @spellchecker = Gni::SolrSpellchecker.new
    @data_sources = options[:data_sources].select {|ds| ds.is_a? Fixnum}
    raise Gni::NameResolverError, MESSAGES[:no_data_source] if @data_sources.blank?
    raise Gni::NameResolverError, MESSAGES[:too_many_data_sources] if @data_sources.size > MAX_DATA_SOURCES 
    raise Gni::NameResolverError, MESSAGES[:no_names] if data.blank?
    raise Gni::NameResolverError, MESSAGES[:too_many_names] if data.size > MAX_NAME_STRING
    @with_context = options[:with_context]
    @names = {}
    @matched_words = {}
    data.each_with_index do |datum, i|
      name_string = datum[:name_string]
      normalized_name_string = NameString.normalize(name_string)
      @names[normalized_name_string] ? @names[normalized_name_string][:indices] << i : @names[normalized_name_string] = { :indices => [i] }
      @names[normalized_name_string][:name_string] = name_string unless @names[normalized_name_string][:name_string]
    end
    @found_words = {}
    if @with_context
      @tree_counter = {}
      @contexts = {}
      @data_sources.each do |i|
        @tree_counter[i] = {}
        @contexts[i] = nil
      end
    end
  end

  def find_exact
    names = get_quoted_names(@names.keys)
    data_sources = @data_sources.join(",")
    q = "select ns.id, ns.uuid, ns.normalized, ns.name, nsi.data_source_id, nsi.taxon_id, nsi.global_id, nsi.url, nsi.classification_path, nsi.classification_path_ids, cf.name from name_string_indices nsi join name_strings ns on ns.id = nsi.name_string_id left outer join canonical_forms cf on cf.id = ns.canonical_form_id where ns.normalized in (#{names})"
    q += " and data_source_id in (#{data_sources})" unless @data_sources.blank?
    res = DataSource.connection.select_rows(q)

    res.each do |row|
      record = {:auth_score => 0, :gni_id => row[0], :name_uuid => UUID.parse(row[1].to_s(16)).to_s, :name => row[3], :data_source_id => row[4], :taxon_id => row[5], :global_id => row[6], :url => row[7], :classification_path => row[8], :classification_path_ids => row[9], :canonical_form => row[10] }
      update_found_words(record[:canonical_form])
      name_normalized = row[2]
      @names[name_normalized][:indices].each do |i|
        datum = data[i]
        canonical_match = NameString.normalize(record[:canonical_form]) == NameString.normalize(record[:name])
        type = NAME_TYPES[record[:canonical_form].split(" ").size]
        record.merge!(:match_type => EXACT_STRING, :name_type => type, :match_by_canonical => canonical_match) 
        datum.has_key?(:results) ? datum[:results] << record : datum[:results] = [record]
        @names[name_normalized].has_key?(:results) ? @names[name_normalized][:results] << record : @names[name_normalized][:results] = [record]
        update_context(record) if @with_context
      end
    end

    @names.keys.each do |key|
      @names.delete(key) if @names[key].has_key?(:results)
    end
  end

  def find_canonical_exact
    return if @names.empty?
    get_canonical_forms
    
    canonical_forms = @names.keys
    names = get_quoted_names(canonical_forms)
    data_sources = @data_sources.join(",")
    
    q = "select ns.id, ns.uuid, null, ns.name, nsi.data_source_id, nsi.taxon_id, nsi.global_id, nsi.url, nsi.classification_path, nsi.classification_path_ids, cf.name, pns.data  from name_string_indices nsi join name_strings ns on ns.id = nsi.name_string_id join canonical_forms cf on cf.id = ns.canonical_form_id join parsed_name_strings pns on pns.id = ns.id where cf.name in (#{names})"
    q += " and data_source_id in (#{data_sources})" unless @data_sources.blank?
    res = DataSource.connection.select_rows(q)
    res.each do |row|
      record = {:gni_id => row[0], :name_uuid => UUID.parse(row[1].to_s(16)).to_s, :name => row[3], :data_source_id => row[4], :taxon_id => row[5], :global_id => row[6], :url => row[7], :classification_path => row[8], :classification_path_ids => row[9], :canonical_form => row[10] }
      found_name_parsed = @atomizer.organize_results(JSON.parse(row[11], :symbolize_names => true)[:scientificName])
      update_found_words(record[:canonical_form])
      @names[record[:canonical_form]].each do |val|
        auth_score = get_authorship_score(val[:parsed], found_name_parsed)
      
        val[:indices].each do |i|
          datum = data[i]
          canonical_match = NameString.normalize(record[:canonical_form]) == NameString.normalize(record[:name])
          type = NAME_TYPES[record[:canonical_form].split(" ").size]
          res = record.merge(:match_type => EXACT_CANONICAL, :name_type => type, :match_by_canonical => canonical_match, :auth_score => auth_score) 
          datum.has_key?(:results) ? datum[:results] << res : datum[:results] = [res]
          val.has_key?(:results) ? val[:results] << res : val[:results] = [res]
          update_context(res) if @with_context
        end
      end
    end
    delete_names_with_results
  end

  def delete_names_with_results
    @names.each do |key, value|
      new_value = value.select {|r| !r.has_key?(:results)}
      if new_value.empty?
        @names.delete(key)
      else
        @names[key] = new_value
      end
    end
  end

  def find_canonical_fuzzy
    data_sources = @data_sources.join(",")
    @names.keys.each do |name|
      canonical_forms = @spellchecker.find(name)
      unless canonical_forms.blank?
        q = "select ns.id, ns.uuid, null, ns.name, nsi.data_source_id, nsi.taxon_id, nsi.global_id, nsi.url, nsi.classification_path, nsi.classification_path_ids, cf.name, pns.data from canonical_forms cf join name_strings ns on ns.canonical_form_id = cf.id join parsed_name_strings pns on pns.id = ns.id join name_string_indices nsi on nsi.name_string_id = ns.id where cf.name in (%s)" % canonical_forms.map { |n| NameString.connection.quote(n) }.join(",")
        q += " and data_source_id in (#{data_sources})" unless @data_sources.blank?
        res = NameString.connection.select_rows(q)
        fuzzy_data = {}
        res.each do |row|
          canonical_form = row[10]
          next if name.split(" ").size != canonical_form.split(" ").size
          is_match = match_names(name, canonical_form) 
          if is_match
            record = {:gni_id => row[0], :name_uuid => UUID.parse(row[1].to_s(16)).to_s, :name => row[3], :data_source_id => row[4], :taxon_id => row[5], :global_id => row[6], :url => row[7], :classification_path => row[8], :classification_path_ids => row[9], :canonical_form => canonical_form }
            found_name_parsed = @atomizer.organize_results(JSON.parse(row[11], :symbolize_names => true)[:scientificName])
            @names[name].each do |val|
              auth_score = get_authorship_score(val[:parsed], found_name_parsed)
              val[:indices].each do |i|
                datum = data[i]
                canonical_match = NameString.normalize(record[:canonical_form]) == NameString.normalize(record[:name])
                type = NAME_TYPES[record[:canonical_form].split(" ").size]
                res = record.merge(:match_type => FUZZY_CANONICAL, :name_type => type, :match_by_canonical => canonical_match, :auth_score => auth_score) 
                datum.has_key?(:results) ? datum[:results] << res : datum[:results] = [res]
                val.has_key?(:results) ? val[:results] << res : val[:results] = [res]
                update_context(res) if @with_context
              end
            end
          end
        end
      end
    end
    delete_names_with_results
  end

  def get_rid_of_unparsed
    #delete found words
    @names.each do |key, values|
      parsed, unparsed = values.partition {|value| value[:canonical_form]}
      if parsed.empty?
        @names.delete(key)
      else
        @names[key] = parsed
      end
      # 
      # unparsed.each do |value|
      #   value[:indices].each do |index|
      #     data[index].merge!({ :match_type => UNPARSEABLE })
      #   end
      # end
    end
  end
  
  def get_canonical_forms
    @names.keys.each do |key|
      @names[key][:parsed] = @atomizer.parse(@names[key][:name_string])
      if @names[key][:parsed]
        @names[key][:canonical_form] = @names[key][:parsed][:canonical_form]
      else
        @names[key][:canonical_form] = nil
      end
    end
    #switch names to canonical forms from normalized names
    new_names = {}
    @names.values.each do |v|
      new_names.has_key?(v[:canonical_form]) ? new_names[v[:canonical_form]] << v : new_names[v[:canonical_form]] = [v]
    end
    @names = new_names
  end

  def get_quoted_names(names_array)
    names_array.map {|name| NameString.connection.quote(name)}.join(",")
  end

  def update_found_words(canonical_form)
    return if canonical_form.blank?
    words = canonical_form.split(" ")
    if words.size > 1 
      genus = (words[0] == "x") ? words[1] : words[0]
      @found_words[genus] = :genus unless @found_words[genus] && @found_words[genus] == :genus
    else
      @found_words[words[0]] = :uninomial unless @found_words[words[0]]
    end
  end

  # Collect data for finding out the list 'context' taxon (for example Aves for birds list)
  def update_context(record)
    return if record[:classification_path].blank?
    taxa = record[:classification_path].split("|")
    data_source_id = record[:data_source_id]
    taxa.each_with_index do |taxon, i|
      if @data_sources.blank?
        update_tree_counter(@tree_counter[Gni::Config.reference_data_source_id], taxon, i)
      else
          update_tree_counter(@tree_counter[data_source_id], taxon, i)
      end
    end
  end

  def update_tree_counter(counter, taxon, index)
    if counter[index] && counter[index][taxon]
      counter[index][taxon] += 1
    elsif counter[index]
      counter[index][taxon] = 1
    else
      counter[index] = { taxon => 1 }
    end
  end

  def get_authorship_score(parsed1, parsed2)
    @taxamatch.match_authors(parsed1, parsed2)  
  end

  def match_names(name1, name2)
    words = name1.split(" ").zip(name2.split(" "))
    count = nil
    words.each_with_index do |w, i|
      return nil unless w[0] && w[1] #should never happen
      count = i
      match = match_words(w[0], w[1], i)
      return nil unless match
    end
    count
  end

  def match_words(word1, word2, index)
    index = 1 if index > 0
    return true if word1 == word2
    words_concatenate = [index.to_s, word1, word2].sort.join("_") 
    return @matched_words[words_concatenate] if @matched_words.has_key?(words_concatenate)
    @matched_words[words_concatenate] = index == 0 ? @taxamatch.match_genera({normalized:word1}, {normalized:word2}, :with_phonetic_match => false)["match"] : @taxamatch.match_species({normalized:word1}, {normalized:word2}, :with_phonetic_match => false)["match"]
  end

  def get_contexts
    @contexts.keys.each do |ds_id|
      tree = @tree_counter[ds_id]
      context = nil
      tree.each do |k,v|
        sum = v.inject(0) { |s, d| s += d[1]; s }
        max = v.sort { |d| d[1] }.last
        break if (max[1].to_f/sum.to_f) < CONTEXT_THRESHOLD
        context = max[0]
      end
      @contexts[ds_id] = context
    end
  end

  def calculate_scores
    data.each do |datum|
      next unless datum[:results]
      datum[:results].each do |result|
        get_score(result)
      end
    end
  end

  def get_score(result)
    name_type = result[:name_type]
    auth_score = result[:auth_score] || 0
    canonical_match = result[:match_by_canonical]
    match_type = result[:match_type]
    data_source_id = result[:data_source_id]
    classification_path = result[:classification_path].split("|")
    context = 0
    if @with_context && !classification_path.empty?
      context = classification_path.include?(@contexts[data_source_id]) ? 1 : -1
    end
    prescore = 0
    if name_type == "uninomial"
      a = auth_score * 2
      c = context * 2
      s = 4
      s = 1 if (canonical_match || match_type == EXACT_CANONICAL)
      if match_type == FUZZY_CANONICAL
        s = 0
        a = auth_score
        c = context
      end
    elsif name_type == "binomial"
      a = auth_score * 2
      c = context * 4
      s = 8
      s = 3 if (canonical_match || match_type == EXACT_CANONICAL)
      if match_type == FUZZY_CANONICAL
        s = 0.5
        a = auth_score
        c = context
      end
    elsif name_type == "trinomial"
      a = auth_score * 2
      c = context
      s = 8
      s = 7 if match_type == EXACT_CANONICAL
      if match_type == FUZZY_CANONICAL
        s = 0.5
        a = auth_score
        c = context
      end
    end
    prescore += (s + a + c)
    result[:prescore] = "%s|%s|%s" % [s,a,c]
    result[:score] = Gni.num_to_score(prescore)
    result[:possible_cresonym] = auth_score < 0 && result[:score] > 0.9 ? true : false
  end
  
  def add_default_options
    self.options = {:with_context => false, :data_sources => []}.merge(self.options)
  end

  def format_result
    r = result
    if @with_context
      r[:context] = []
      @contexts.each do |key, val|
        r[:context] << { :data_source_id => key, :clade => val }
      end
    end
    r[:data] = []
    data.each do |d|
      res = { :name_string => d[:name_string] } 
      res[:id] = d[:id] if d[:id]
      if d[:results]
        res[:results] = []
        d[:results].each do |dr|
          match = {}
          match[:data_source_id] = dr[:data_source_id]
          match[:gni_uuid] = dr[:name_uuid]
          match[:name_string] = dr[:name]
          match[:canonical_form] = dr[:canonical_form]
          match[:classification_path] = dr[:classification_path]
          match[:classification_path_ids] = dr[:classification_path_ids]
          match[:taxon_id] = dr[:taxon_id]
          #placeholders for the future
          #match[:guid] = dr[:guid]
          #match[:urls] = [] 
          if dr[:classification_path_ids]
            last_classification_id = dr[:classification_path_ids].split("|").last
            if last_classification_id && last_classification_id != dr[:taxon_id]
              ns = NameString.connection.select_value("select name from name_strings ns join name_string_indices nsi on nsi.name_string_id = ns.id where nsi.taxon_id = %s and data_source_id = %s limit 1" % [NameString.connection.quote(last_classification_id), NameString.connection.quote(dr[:data_source_id])])
              match[:current_taxon_id] = last_classification_id
              match[:current_name_string] = ns if ns
            end
          end
          match[:match_type] = dr[:match_type]
          match[:prescore] = dr[:prescore]
          match[:score] = dr[:score]
          res[:results] << match
        end
      end
      r[:data] << res
    end
    save!
  end

end
