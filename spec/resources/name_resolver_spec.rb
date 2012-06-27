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
    res[:data].select { |r| r.has_key?(:id) }.size.should > 0
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

  it "should be able to use uploaded file for resolving names" do
    file_test_names = File.join(File.dirname(__FILE__), '..', 'files', 'bird_names.txt')
    file = Rack::Test::UploadedFile.new(file_test_names, 'text/plain')
    post('/name_resolvers.json', :file => file, :data_source_ids => "1|2")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:data][1][:results].first[:taxon_id].should == "2433879"
  end

  it "should produce an error if there is no data source information" do
    get("/name_resolvers.json", 
        :names => "Leiothrix argentauris (Hodgson, 1838)|Treron|Larus occidentalis wymani|Plantago major L.",
        :with_context => false)
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:status].should == ProgressStatus.failed.name
    res[:message].should == NameResolver::MESSAGES[:no_data_source]
  end
  
  it "should produce an error if there are too many data sources" do
    get("/name_resolvers.json", 
        :names => "Leiothrix argentauris (Hodgson, 1838)|Treron|Larus occidentalis wymani|Plantago major L.",
        :with_context => false,
        :data_source_ids => "1|2|3|4|5|6")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:status].should == ProgressStatus.failed.name
    res[:message].should == NameResolver::MESSAGES[:too_many_data_sources]
  end

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
