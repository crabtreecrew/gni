require File.dirname(__FILE__) + '/../spec_helper'

describe "/uuids" do
  describe "index" do
    
    before (:all) do
      names = ["Betula verucosa", "Parus major"].join("|")
      names = URI.encode(names)
      visit("/uuids.xml?names=#{names}")
      @xml_res = body
      page.status_code.should == 200
      visit("/uuids.yaml?names=#{names}")
      @yaml_res = body
      page.status_code.should == 200
      visit("/uuids.json?names=#{names}&callback=myFunc")
      @json_res = body
      page.status_code.should == 200
    end

    it "should get valid xml" do
      dom = Nokogiri::XML(@xml_res)
      dom.xpath("//record[1]/name").text.should == "Betula verucosa"
      dom.xpath("//record[1]/uuid").text.should == "4c19ac07-ec67-5cff-97bf-7d9ecbe12e34"
      dom.xpath("//record").size.should == 2
    end  
    
    it "should render yaml" do
      @yaml_res.should include("--")
      @yaml_res.should include("Parus major")
      @yaml_res.should include("47d61c81-5a0f-5448-964a-34bbfb54ce8b")
    end

    it "should render json" do
      names_json = @json_res.match(/\((.*)\)/)[1] 
      res = JSON.load(names_json)
      @json_res.match(/^myFunc/).should_not be_nil
      res[0]['name'].should == "Betula verucosa"
    end

    it "should remove double spaces and spaces on edges" do
      name = URI.encode("    Betula         verucosa            ")
      visit("/uuids.json?names=#{name}")
      res = JSON.load(body)
      res[0]["name"].should == "Betula verucosa"
      res[0]["uuid"].should == "4c19ac07-ec67-5cff-97bf-7d9ecbe12e34"
    end

  end
end
