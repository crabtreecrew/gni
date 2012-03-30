require 'spec_helper'
include ApiHelper

describe "data_sources API" do
  it "should be able to return all known data_sources" do 
    get("/data_sources.json")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res.size.should > 1
    res.select {|ds| ds[:title].to_s.match /ITIS/}.size.should > 0
  end

  it "should be able to return search results" do
    get("/data_sources.json?search_term=itis")
    body = last_response.body
    res = JSON.parse(body, :symbolize_names => true)
    res.size.should > 0
    res.select {|ds| ds[:title].to_s.match /ITIS/}.size.should > 0
  end

  it "should work with callback parameter in json format" do
    get("/data_sources.json?search_term=itis&callback=myMethod")
    body = last_response.body
    body.match(/myMethod\(/).should be_true
  end
end

