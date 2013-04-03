require 'spec_helper'
include ApiHelper

describe "nomenclatural_codes API" do
  it 'should generate web page' do
    get("/nomenclatural_codes")
    body = last_response.body
    body.include?('International Code of Zoological Nomenclature').
      should be_true
  end

  it 'should be able to return all known nomenclatural codes in json' do 
    get("/nomenclatural_codes.json")
    body = last_response.body
    res = JSON.parse(body, symbolize_names: true)
    res.size.should > 1
    res.map { |r| r[:code] }.should == %w(ICN ICZN ICNB ICNCP ICTV ICPN)
  end
  
  it 'should return all known nomenclatural codes in xml' do 
    get("/nomenclatural_codes.xml")
    body = last_response.body
    codes = Nokogiri::XML.parse(body).xpath('//code').map {|x| x.text}
    codes.should == %w(ICN ICZN ICNB ICNCP ICTV ICPN)
  end
end


