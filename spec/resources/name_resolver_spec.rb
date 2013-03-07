require 'spec_helper'
include ApiHelper

describe "name_resolvers API" do

  it "should be able to use GET for resolving names" do
    get("/name_resolvers.json", 
        :names => "Leiothrix argentauris (Hodgson, 1838)|Treron|Larus occidentalis wymani|Plantago major L.",
        :data_source_ids => "1|3")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:data].first[:results].first[:taxon_id].should == "6868221"
  end

  it "should not contain id field if user did not supply id" do
    get("/name_resolvers.json", 
        :names => "Leiothrix argentauris (Hodgson, 1838)|Treron|Larus occidentalis wymani|Plantago major L.",
        :data_source_ids => "1|3")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:data].select { |r| r.has_key?(:id) }.size.should == 0
  end
  
  it "github #6: should be able to use GET for only uninomials" do
    get("/name_resolvers.json", 
        :names => "Rhizoclonium",
        :data_source_ids => "1|3")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res.size.should > 0
  end
  
  it "should parse options correctly" do
    get("/name_resolvers.json", 
        :names => "Leiothrix argentauris (Hodgson, 1838)|Treron|Larus occidentalis wymani|Plantago major L.",
        :data_source_ids => "1|3",
        :with_context => false)
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:parameters][:with_context].should == false
  end

  it "should be able to use POST for resolving names" do
    post("/name_resolvers.json", 
        :data => "1|Leiothrix argentauris (Hodgson, 1838)\n2|Treron\n3|Larus occidentalis wymani\n4|Plantago major L.",
        :data_source_ids => "1|3")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:data].first[:results].first[:taxon_id].should == "6868221"
    res[:data].select { |r| r.has_key?(:supplied_id) }.size.should > 0
  end

  it "should be able to continue with canonical form search if resolve_once option is false" do
    post("/name_resolvers.json", 
        :data => "2|Calidris cooperi\n1|Leiothrix argentauris\n4|Plantago major L.",
        :data_source_ids => "1|3", :resolve_once => true)
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:data][1][:results].size.should == 1
    res[:data][1][:results][0][:name_string].should == 'Leiothrix argentauris'
    post("/name_resolvers.json", 
        :data => "2|Calidris cooperi\n1|Leiothrix argentauris\n4|Plantago major L.",
        :data_source_ids => "1|3", :resolve_once => false)
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:data][1][:results].size.should == 3
    res[:data][1][:results].map {|r| r[:data_source_id]}.should == [1,1,3]
  end

  it "should be able to find partial binomial and partial uninomial forms" do
    post("/name_resolvers.json", 
        :data => "2|Calidris cooperi alba\n1|Liothrix argentauris something something\n4|Plantago major L.\n5|Treron somthing",
        :resolve_once => false)
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:data][-1].should == {:supplied_name_string=>"Treron somthing", :supplied_id=>"5", :results=>[{:data_source_id=>1, :gni_uuid=>"02450740-2179-4891-4420-116063658828", :name_string=>"Treron", :canonical_form=>"Treron", :classification_path=>"Animalia|Chordata|Aves|Columbiformes|Columbidae|Treron", :classification_path_ids=>"2362377|2362754|2363138|2363188|2363295|2378348", :taxon_id=>"2378348", :match_type=>6, :prescore=>"1|0|0", :score=>0.75}]}
    res[:data][-3][:supplied_name_string].should == 'Liothrix argentauris something something'
    res[:data][-3][:results].map {|r| [r[:match_type], r[:score]]}.should == [[5, 0.75], [5, 0.75], [5, 0.75]] 
  end

  it "should create default options" do
    post("/name_resolvers.json", 
        :data => "2|Calidris cooperi\n1|Leiothrix argentauris\n4|Plantago major L.")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:parameters].should == {:with_context => false, :data_sources => [], :resolve_once => false}
  end

  it "should be able to use uploaded file for resolving names" do
    file_test_names = File.join(File.dirname(__FILE__), '..', 'files', 'bird_names.txt')
    file = Rack::Test::UploadedFile.new(file_test_names, 'text/plain')
    post('/name_resolvers.json', :file => file, :data_source_ids => "1|2")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:data][1][:results].first[:taxon_id].should == "2433879"
  end

  it "should search whole GNI if there is no data source information" do
    get("/name_resolvers.json", 
        :names => "Calidris cooperi|Liothrix argentauris|Leiothrix argentauris (Hodgson, 1838)|Treron|Larus occidentalis wymani|Plantago major L.",
        :with_context => false, :resolve_once => false)
    body = last_response.body
    
    res = JSON.parse(body, :symbolize_names => true)
    res[:data][0][:results].first.should == {:data_source_id=>2, :gni_uuid=>"01435442-3983-5234-9623-022468658894", :name_string=>"Calidris cooperi", :canonical_form=>"Calidris cooperi", :classification_path=>nil, :classification_path_ids=>nil, :taxon_id=>"5679", :match_type=>1, :prescore=>"3|0|0", :score=>0.988}
    res[:data][1][:results].first.should == {:data_source_id=>1, :gni_uuid=>"01052127-9074-3279-3448-709966846776", :name_string=>"Leiothrix argentauris (Hodgson, 1838)", :canonical_form=>"Leiothrix argentauris", :classification_path=>"Animalia|Chordata|Aves|Passeriformes|Sylviidae|Leiothrix|Leiothrix argentauris", :classification_path_ids=>"2362377|2362754|2363138|2363139|2363166|2417185|6868221", :taxon_id=>"6868221", :match_type=>3, :prescore=>"1|0|0", :score=>0.75}
  end

  it "should be able to find as best as it can species with lost epithets, with cf or aff qualifiers" do
    get("/name_resolvers.json", 
        :names => "Calidris cf. cooperi|Liothrix argentauris ssp.|Treron aff. argentauris (Hodgson, 1838)|Treron spp.|Calidris cf. cooperi",
        :resolve_once => false)
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res0 = res[:data][0]
    res0[:supplied_name_string].should == "Calidris cf. cooperi"
    res0[:results].map {|r| r[:name_string]}.uniq.should == ["Calidris cooperi (Baird, 1858)", "Calidris cooperi"]
    res1 = res[:data][1]
    res1[:supplied_name_string].should == "Liothrix argentauris ssp."
    res1[:results].map {|r| r[:name_string]}.uniq.should == ["Leiothrix argentauris (Hodgson, 1838)", "Leiothrix argentauris"] 
    res2 = res[:data][2]
    res2[:supplied_name_string].should == "Treron aff. argentauris (Hodgson, 1838)"
    res2[:results].map {|r| r[:name_string]}.uniq.should == ["Treron"] 
    res3 = res[:data][3]
    res3[:supplied_name_string].should == "Treron spp."
    res3[:results].map {|r| r[:name_string]}.uniq.should == ["Treron"] 
    res4 = res[:data][4]
    res4[:supplied_name_string].should == 'Calidris cf. cooperi'
    res4[:results].map { |r| r[:name_string] }.uniq.should == ['Calidris cooperi (Baird, 1858)', 'Calidris cooperi']
  end
  
  # REMOVED this CONSTRAIN FOR NOW
  # it "should produce an error if there are too many data sources" do
  #   get("/name_resolvers.json", 
  #       :names => "Leiothrix argentauris (Hodgson, 1838)|Treron|Larus occidentalis wymani|Plantago major L.",
  #       :with_context => false,
  #       :data_source_ids => "1|2|3|4|5|6")
  #   body = last_response.body
  #   res = JSON.parse(body, :symbolize_names => true)
  #   res[:status].should == ProgressStatus.failed.name
  #   res[:message].should == NameResolver::MESSAGES[:too_many_data_sources]
  # end

  it "should produce an error if there are no names" do
    get("/name_resolvers.json", 
        :names => "",
        :data_source_ids => "1|3",
        :with_context => false)
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:status].should == ProgressStatus.failed.name
    res[:message].should == NameResolver::MESSAGES[:no_names]
  end
  
  it "should produce an error if there are too many names and make sure GET is executed without que" do
    get("/name_resolvers.json", 
        :names => (NameResolver::MAX_NAME_STRING + 1).times.inject([]) { |res| res << "Plantago major"; res }.join("|"),
        :data_source_ids => "1")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:status].should == ProgressStatus.failed.name
    res[:message].should == NameResolver::MESSAGES[:too_many_names]
  end

end
