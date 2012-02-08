module Gni
  class SolrClient

    attr_reader :url

    def initialize(opts) 
      opts = { solr_url: Gni::Config.solr_url, update_csv_params: "" }.merge(opts)
      @url = opts[:solr_url]
      @url_update = @url + "/update"
      # @url_update_csv = @url + "/update/csv?wt=json&f.common_name.split=true&f.scientific_name_synonym_exact.split=true&f.scientific_name_synonym.split=true&stream.contentType=text/plain;charset=utf-8&stream.file=%s&commit=%s"
      @url_update_csv = @url + "/update/csv?wt=json&stream.contentType=text/plain;charset=utf-8&stream.file=%s&commit=%s" + opts[:update_csv_params]
      @url_search = @url + '/select/?version=2.2&indent=on&wt=json&q='
    end


    def commit
      post('<commit />')
    end

    def update_with_xml(xml_data, to_commit = true)
      post(xml_data)
      commit if to_commit
    end

    def update_with_csv(csv_file, to_commit = true)
      url = @url_update_csv % [csv_file, to_commit.to_s] 
      require 'ruby-debug'; debugger
      get(url)
    end

    def update(ruby_data, to_commit = true)
      xml_data = build_solr_xml(ruby_data)
      post(xml_data)
      commit if to_commit
    end

    def delete(query, to_commit = true)
      post("<delete><query>#{query}</query></delete>")
      commit if to_commit
    end

    def delete_all
      post('<delete><query>*:*</query></delete>')
      commit
    end

    def search(query, options = {})
      get_query(query, options)
    end

    alias :create :update
    alias :query :search

    private
    def post(xml_data, url = nil)
      url ||= @url_update
      RestClient.post url, xml_data, :content_type => :xml, :accept => :xml
    end

    def get(url)
      JSON.parse(RestClient.get(url, {:accept => :json}), :symbolize_names => true)
    end

    def get_query(query, options)
      url = @url_search.dup 
      url << set_query(query, options)
      JSON.parse(RestClient.get(url, {:accept => :json}), :symbolize_names => true)
    end

    def set_query(query, options)
      res = URI.encode(%Q[{!lucene} #{query}])
      limit  = options[:per_page] ? options[:per_page].to_i : 30 
      page = options[:page] ? options[:page].to_i : 1
      offset = (page - 1) * limit
      res << '&start=' << URI.encode(offset.to_s)
      res << '&rows='  << URI.encode(limit.to_s)
      res
    end

    # Takes an array of hashes. Each hash has only string or array of strings values. Array is converted into an xml ready
    # for either create or update methods of Solr API  #
    # See the solr_api library spec for some examples.
    def build_solr_xml(ruby_data)
      builder = Nokogiri::XML::Builder.new do |sxml|
        sxml.add do 
          ruby_data = [ruby_data] if ruby_data.class != Array
          ruby_data.each do |data|
            sxml.doc_ do
              data.keys.each do |key|
                data[key] = [data[key]] if data[key].class != Array
                data[key].each do |val|
                  sxml.field(val, :name => key.to_s) 
                end
              end
            end
          end
        end
      end
      builder.to_xml
    end  

  end
end
