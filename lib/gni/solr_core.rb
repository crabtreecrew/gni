# encoding: utf-8
module Gni
  class SolrIngest
    # @queue = :solr_ingest

    # def self.perform(solr_injest_id, solr_url = Gni::Config.solr_url)
    #   classification = SolrIk.first(:id => classification_id)    
    #   raise RuntimeError, "No classification with id #{classification_id}" unless classification
    #   si = SolrIngest.new(classification, solr_url)
    #   si.ingest
    # end

    def initialize(core)
      @core = core
      @solr_client = SolrClient.new(solr_url: core.solr_url, update_csv_params: core.update_csv_params)
      @temp_file = "solr_" + @core.name + "_"
    end

    def ingest
      id_start = 4910000 #0
      id_start = 7940001
      id_end = id_start + Gni::Config.batch_size
      while id_start <= NameString.maximum(:id) do
        rows = @core.get_rows(id_start, id_end)
        unless rows.blank? 
          @csv_file_name = File.join(Gni::Config.temp_dir, (@temp_file + "%s_%s" % [id_start, id_end]))
          csv_file = create_csv_file
          rows.each { |row| csv_file << row }
          csv_file.close
          #@solr_client.delete("name_string_id:[%s TO %s]" % [id_start, id_end])
          @solr_client.update_with_csv(@csv_file_name)
          FileUtils.rm(@csv_file_name)
        end
        id_start = id_end
        id_end += Gni::Config.batch_size
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
        @stemmer= Lingua::Stemmer.new(:language => "latin")
        @solr_url = Gni::Config.solr_url + "/" + @name
        @fields = %w(name_string_id canonical_form_id name_string canonical_form canonical_form_size canonical_word1 canonical_word2 canonical_word2_stem canonical_word3 canonical_word3_stem uninomial_auth uninomial_yr genus_auth genus_yr species_auth species_yr infraspecies_auth infraspecies_yr)
        @update_csv_params = "&" + @fields[4..-1].map { |f| "f.%s.split=true" % f }.join("&")
      end

      def get_rows(id_start, id_end)
        puts "data from %s to %s" % [id_start +1, id_end]
        q = "select ns.id as name_string_id, cf.id as canonical_form_id, ns.name as name_string, cf.name as canonical_form, pns.data from name_strings ns join parsed_name_strings pns on pns.id=ns.id join canonical_forms cf on cf.id = ns.canonical_form_id where ns.canonical_form_id is not null and ns.id > %s and ns.id <= %s" % [id_start, id_end]
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
          uninomial_auth = res[:uninomial] ? res[:uninomial][:normalized_authors] : []
          uninomial_years = res[:uninomial] ? res[:uninomial][:years] : []
          genus_auth = res[:genus] ? res[:genus][:normalized_authors] : []
          genus_years = res[:genus] ? res[:genus][:years] : []
          species_auth = res[:species] ? res[:species][:normalized_authors] : []
          species_years = res[:species] ? res[:species][:years] : []
          infraspecies_auth = res[:infraspecies] ? res[:infraspecies][0][:normalized_authors] : []
          infraspecies_years = res[:infraspecies] ? res[:infraspecies][0][:years] : []
          [words.size, word1, word2, stem2,  word3, stem3].each { |var| row << var.to_s }
          [uninomial_auth, uninomial_years, genus_auth, genus_years, species_auth, species_years, infraspecies_auth, infraspecies_years].each do |var|
            row << var.join(",")
          end
        end
        rows
      end

    end

    class SolrCoreCanonicalFormIndex < SolrCoreCanonicalForm
      def initialize
        super
        @name = "canonical_forms_data_sources"
        @solr_url = Gni::Config.solr_url + "/" + @name
        @fields += %w(data_source_id taxon_id classification_path classification_path_verbatim)
        @fields.unshift("name_string_index_id")
        @update_csv_params += "&f.classification_path.split=true"
      end

      def get_rows(id_start, id_end)
        rows = super
        indices = []
        rows.each do |row|
          q = "select data_source_id, taxon_id, classification_path from name_string_indices where name_string_id = %s" % row[0]
          indices_rows = NameString.connection.select_rows(q)
          if indices_rows.blank? 
            puts "not data for id %s" % row[0]
            indices << ([row[0].to_s + "__"] + row[0..-1] + ["", "", "", ""])
          else
            indices_rows.each do |index|
              indices << ["%s_%s_%s" % [row[0], index[0], index[1]]] + row[0..-1] + [index[0], index[1], index[2].gsub("|", ","), index[2]]
            end
          end
        end
        indices
      end
    end
  end
