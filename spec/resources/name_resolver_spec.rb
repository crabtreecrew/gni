require 'spec_helper'
include ApiHelper

describe "name_resolvers API" do

  it "should be able to use GET for resolving names" do
    get("/name_resolvers.json", 
        :names => "Leiothrix argentauris (Hodgson, 1838)|Treron|Larus occidentalis wymani|Plantago major L.",
        :data_source_ids => "1|2")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:data].first[:results].first[:taxon_id].should == "6868221"
  end
  
  it "github #6: should be able to use GET for only uninomials" do
    get("/name_resolvers.json", 
        :names => "Rhizoclonium",
        :data_source_ids => "1|2")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res.size.should > 0
  end
  
  it "should parse options correctly" do
    get("/name_resolvers.json", 
        :names => "Leiothrix argentauris (Hodgson, 1838)|Treron|Larus occidentalis wymani|Plantago major L.",
        :data_source_ids => "1|2",
        :with_context => false)
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:parameters][:with_context].should == false
  end

  it "should be able to use POST for resolving names" do
    post("/name_resolvers.json", 
        :data => "1|Leiothrix argentauris (Hodgson, 1838)\n2|Treron\n3|Larus occidentalis wymani\n4|Plantago major L.",
        :data_source_ids => "1|2")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:data].first[:results].first[:taxon_id].should == "6868221"
  end

  it "should be able to use uploaded file for resolving names" do
    file_test_names = File.join(File.dirname(__FILE__), '..', 'files', 'bird_names.txt')
    file = Rack::Test::UploadedFile.new(file_test_names, 'text/plain')
    post('/name_resolvers.json', :file => file, :data_source_ids => "1|2")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res[:data][1][:results].first[:taxon_id].should == "2433879"
  end
end
