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
  end

private

  def prepare_variables
    @data_sources = options[:data_sources].select {|ds| ds.is_a? Fixnum}
    @with_conext = options[:with_context]
    @names = {}
    data.each_with_index do |datum, i|
      name_string = datum[:name_string]
      normalized_name_string = NameString.normalize(name_string)
      @names[normalized_name_string] ? @names[normalized_name_string][:indices] << i : @names[normalized_name_string] = { :indices => [i] }
    end
  end

  def find_exact
    names = @names.keys.map {|name| NameString.connection.quote(name)}.join(",")
    data_sources = @data_sources.join(",")
    q = "select ns.id, ns.uuid, ns.normalized, ns.name, nsi.data_source_id, nsi.taxon_id, nsi.global_id, nsi.url, nsi.classification_path from name_string_indices nsi join name_strings ns on ns.id = nsi.name_string_id where ns.normalized in (#{names})"
    q += " and data_source_id in (#{data_sources})" unless @data_sources.blank?
    res = DataSource.connection.select_rows(q)

    res.each do |row|
       record = {:gni_id => row[0], :name_uuid => row[1], :name_normalized => row[2], :name => row[3], :data_source_id => row[4], :taxon_id => row[5], :global_id => row[6], :url => row[7], :classification_path => row[8]}
       @names[record[:name_normalized]][:indices].each do |datum|
         datum.has_key?(:results) ? datum(:results) << record : datum[:results] = [record]
       end
    end


  end

end
