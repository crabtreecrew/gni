require 'spec_helper'
include ApiHelper

describe "nomenclatural_codes API" do
  it 'should be able to return all known nomenclatural_coes' do 
    get("/nomenclatural_codes.json")
    body = last_response.body
    res = JSON.parse(body, symbolize_names: true)
    res.size.should > 1
    res.map { |r| r[:code] }.should == %w(ICN ICZN ICNB ICNCP ICTV ICPN)
  end
end


