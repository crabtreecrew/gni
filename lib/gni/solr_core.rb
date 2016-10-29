# encoding: utf-8
module Gni
  class SolrSpellchecker

    @queue = :solr_search

    def self.perform(id, name)
      spellchecker = Gni::SolrSpellchecker.new
      cfs = spellchecker.find(name + '~')
      cfs -= [name.downcase]
      unless cfs.empty?
        cfs.each do |candidate_name|
          NameString.connection.execute("
            INSERT IGNORE INTO lexical_match_candidates
              (canonical_form_id, candidate_name, created_at, updated_at)
              values (%s, %s, now(), now())" %
              [id, NameString.connection.quote(candidate_name)])
        end
      end
    end

    def initialize
      @core = SolrCoreCanonicalForm.new
      @solr_client = SolrClient.new(solr_url: @core.solr_url,
                                    update_csv_params: @core.update_csv_params)
    end

    def find(name)
      res = @solr_client.search('*:*&rows=0&spellcheck=true&'\
                                'spellcheck.accuracy=0.8&'\
                                "spellcheck.q=#{name}&spellcheck.rows=1000")

      if res[:spellcheck][:suggestions].blank?
        []
      else
        res[:spellcheck][:suggestions][1][:suggestion]
      end
    end
  end

  class SolrIngest

    def initialize(core)
      @core = core
      @solr_client = SolrClient.new(solr_url: core.solr_url,
                                    update_csv_params: core.update_csv_params)
      @temp_file = "solr_" + @core.name + "_"
    end

    def delete_all
      @solr_client.delete_all
    end

    def build_spellcheck_index
      @solr_client.search("*:*&rows=0&spellcheck.build=true&spellcheck=true")
    end

    def ingest
      offset = 0
      while offset <= @core.count do
        rows = @core.get_rows(offset)
        @csv_file_name = File.join(Gni::Config.temp_dir,
                                  (@temp_file + "%s_%s" %
                                   [offset, offset + Gni::Config.batch_size]))
        csv_file = create_csv_file
        rows.each { |row| csv_file << row }
        csv_file.close
        @solr_client.update_with_csv(@csv_file_name)
        FileUtils.rm(@csv_file_name)
        offset += Gni::Config.batch_size
      end
      if @core.spellcheck?
        puts "Building spellcheck index"
        build_spellcheck_index
      end
    end

    private

    def create_csv_file
      csv_file = CSV.open(@csv_file_name, "w:utf-8")
      csv_file << @core.fields
      csv_file
    end

  end

  class SolrCoreCanonicalForm
    attr :update_csv_params, :fields, :name, :solr_url

    def initialize
      @atomizer = Taxamatch::Atomizer.new
      @name = "canonical_forms"
      @solr_url = Gni::Config.solr_url + "/" + @name
      @fields = %w(canonical_form_id canonical_form canonical_form_size)
      @update_csv_params = ""
    end

    def count
      @count ||= CanonicalForm.count
    end

    def spellcheck?
      true
    end

    def get_rows(offset)
      puts "data from %s to %s" % [offset + 1, offset + Gni::Config.batch_size]
      id_start = CanonicalForm.select(:id).
        order(:id).limit(1).offset(offset).first.id
      id_start = 0 if id_start == 1
      end_offset = [offset + Gni::Config.batch_size, count - 1].min
      id_end = CanonicalForm.select(:id).
        order(:id).limit(1).offset(end_offset).first.id
      q = "
        select id as canonical_form_id,
               name as canonical_form
        from canonical_forms
        where id > %s and id <= %s" % [id_start, id_end]
      rows = CanonicalForm.connection.select_rows(q)
      rows.each do |row|
        canonical_form = row[1]
        words =  canonical_form.split(' ')
        row << words.size.to_s
      end
      rows
    end

  end

  class SolrCoreNameString
    attr :update_csv_params, :fields, :name, :solr_url

    def initialize
      @atomizer = Taxamatch::Atomizer.new
      @name = "canonical_forms"
      @stemmer= Lingua::Stemmer.new(:language => "latin")
      @solr_url = Gni::Config.solr_url + "/" + @name
      @fields = %w(name_string_id canonical_form_id name_string
                   canonical_form canonical_form_size canonical_word1
                   canonical_word2 canonical_word2_stem canonical_word3
                   canonical_word3_stem uninomial_auth uninomial_yr
                   genus_auth genus_yr species_auth
                   species_yr infraspecies_auth infraspecies_yr)
      @update_csv_params = "&" + @fields[4..-1].
        map { |f| "f.%s.split=true" % f }.join("&")
    end

    def count
      @count ||= NameString.count
    end

    def spellcheck?
      false
    end

    def get_rows(offset)
      puts "data from %s to %s" % [offset + 1, offset + Gni::Config.batch_size]
      id_start = NameString.select(:id).
        where("canonical_form_id is not null").
        order(:id).limit(1).offset(offset).first.id
      id_end = NameString.select(:id).where("canonical_form_id is not null").
        order(:id).limit(1).offset(offset + Gni::Config.batch_size).first.id
      q = "
        select
          ns.id as name_string_id,
          cf.id as canonical_form_id,
          ns.name as name_string,
          cf.name as canonical_form,
          pns.data from name_strings ns
        join parsed_name_strings pns
          on pns.id=ns.id
        join canonical_forms cf
          on cf.id = ns.canonical_form_id
        where ns.canonical_form_id is not null
          and ns.id > %s and ns.id <= %s" % [id_start, id_end]
      rows = NameString.connection.select_rows(q)
      rows.each do |row|
        data = JSON.parse(row.pop, :symbolize_names => true)[:scientificName]
        # skipping hybrids and multy infraspecies for now
        next unless data[:details]
        canonical_form = row[3]
        word1 = word2 = word3 = stem2 = stem3 = nil
        words =  canonical_form.split(' ')
        if words.size < 4 || !canonical_form.index('×')
          word1, word2, word3 = words
          word1 = word1.downcase
          stem2, stem3 = [word2, word3].map {|w| @stemmer.stem(w)}
        end
        res = @atomizer.organize_results(data)
        uninomial_auth = res[:uninomial] ?
          res[:uninomial][:normalized_authors] : []
        uninomial_years = res[:uninomial] ?  res[:uninomial][:years] : []
        genus_auth = res[:genus] ? res[:genus][:normalized_authors] : []
        genus_years = res[:genus] ? res[:genus][:years] : []
        species_auth = res[:species] ? res[:species][:normalized_authors] : []
        species_years = res[:species] ? res[:species][:years] : []
        infraspecies_auth = res[:infraspecies] ?
          res[:infraspecies][0][:normalized_authors] : []
        infraspecies_years = res[:infraspecies] ?
          res[:infraspecies][0][:years] : []
        [words.size, word1, word2, stem2,  word3, stem3].
          each { |var| row << var.to_s }
        [uninomial_auth, uninomial_years,
          genus_auth, genus_years, species_auth,
          species_years, infraspecies_auth, infraspecies_years].each do |var|
          row << var.join(",")
        end
      end
      rows
    end

  end

  class SolrCoreNameStringIndex < SolrCoreNameString
    def initialize
      super
      @name = "name_string_indices"
      @solr_url = Gni::Config.solr_url + "/" + @name
      @fields += %w(data_source_id taxon_id
                    classification_path classification_path_verbatim)
      @fields.unshift("name_string_index_id")
      @update_csv_params += "&f.classification_path.split=true"
    end

    def get_rows(offset)
      rows = super
      indices = []
      rows.each do |row|
        q = "
          select data_source_id, taxon_id, classification_path
          from name_string_indices
          where name_string_id = %s" % row[0]
        indices_rows = NameString.connection.select_rows(q)
        if indices_rows.blank?
          puts "not data for id %s" % row[0]
          indices << ([row[0].to_s + "__"] + row[0..-1] + ["", "", "", ""])
        else
          indices_rows.each do |index|
            indices << ["%s_%s_%s" % [row[0], index[0],
                        index[1]]] + row[0..-1] +
                        [index[0], index[1], index[2].gsub("|", ","), index[2]]
          end
        end
      end
      indices
    end
  end
end
