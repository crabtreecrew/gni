require 'iconv'
class ExternalListReconciler < ActiveRecord::Base
  belongs_to :progress_status

  serialize :data, Array
  serialize :options, Hash
  
  def self.perform(reconciler_id)
    r = Reconciler.find(reconciler_id)
    r.reconcile
  end

  def options
    {:with_context => true, :data_sources => []}.merge(super)
  end

  def self.read_file(file_path)
    conv = Iconv.new('UTF-8', 'ISO-8859-1')
    open(file_path).inject([]) do |res, line|
      #for now we assume that non-utf8 charachters are in latin1, might need to add others
      line = conv.conv(line) unless line.valid_encoding?
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

  def reconcile
    prepare_variables
    find_exact
    find_canonical_exact
    require 'ruby-debug'; debugger
    puts ''
  end

private

  def prepare_variables
    @data_sources = options[:data_sources].select {|ds| ds.is_a? Fixnum}
    @with_context = options[:with_context]
    @names = {}
    data.each_with_index do |datum, i|
      name_string = datum[:name_string]
      normalized_name_string = NameString.normalize(name_string)
      @names[normalized_name_string] ? @names[normalized_name_string][:indices] << i : @names[normalized_name_string] = { :indices => [i] }
      @names[normalized_name_string][:name_string] = name_string unless @names[normalized_name_string][:name_string]
    end
    @found_words = {}
    if @with_context
      @tree_counter = {}
      if @data_sources.blank?
        raise "You have to define reference data source" unless Gni::Config.reference_data_source_id
        @tree_counter[Gni::Config.reference_data_source_id] = {}
      else
        @data_sources.each do |i|
          @tree_counter[i] = {}
        end
      end
    end
  end

  def find_exact
    names = @names.keys.map {|name| NameString.connection.quote(name)}.join(",")
    data_sources = @data_sources.join(",")
    q = "select ns.id, ns.uuid, ns.normalized, ns.name, nsi.data_source_id, nsi.taxon_id, nsi.global_id, nsi.url, nsi.classification_path, nsi.classification_path_ids, cf.name from name_string_indices nsi join name_strings ns on ns.id = nsi.name_string_id left outer join canonical_forms cf on cf.id = ns.canonical_form_id where ns.normalized in (#{names})"
    q += " and data_source_id in (#{data_sources})" unless @data_sources.blank?
    res = DataSource.connection.select_rows(q)

    res.each do |row|
      record = {:score => 1.0, :gni_id => row[0], :name_uuid => UUID.parse(row[1]).to_s, :name_normalized => row[2], :name => row[3], :data_source_id => row[4], :taxon_id => row[5], :global_id => row[6], :url => row[7], :classification_path => row[8], :classification_path_ids => row[9], :canonical_form => row[10] }
      update_found_words(record[:canonical_form])
      @names[record[:name_normalized]][:indices].each do |i|
        datum = data[i]
        datum.has_key?(:results) ? datum[:results] << record : datum[:results] = [record]
        @names[record[:name_normalized]].has_key?(:results) ? @names[record[:name_normalized]][:results] << record : @names[record[:name_normalized]][:results] = [record]
        update_context(record) if @with_context
      end
    end

    #delete found words
    @names.each do |key, value|
      @names.delete(key) if value.has_key?(:results)
    end
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

  def find_canonical_exact
    parser = Taxamatch::Atomizer.new
    @names.each do |key, value|
      value[:parsed] = parser.parse(value[:name_string])
    end
  end

end
