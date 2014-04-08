require 'spec_helper'
include ApiHelper

describe "name_string_indices API" do
  
  it "should be able to search for local_ids" do 
    get("/name_string_indices.json", data_source_id: 1, local_id: 4272)
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res.size.should eq 1
    res.select {|ds| ds[:title].to_s.match /ITIS/}.size.should > 0
  end
end
