require File.dirname(__FILE__) + '/../spec_helper'

describe '/parsers' do
  
  describe 'index' do
    it 'should render' do
      visit('/parsers.xml?names=Betula%20verucosa;Parus+major')
      page.status_code == 200
      body.should have_tag('scientific_name')
      visit('/parsers.json?names=Betuls+verucosa&callback=myfunc')
      page.status_code == 200
      body.should include('myfunc([')
    end
  end
  
  describe 'new' do
    it 'should render' do
      visit('/parsers/new')
      page.status_code == 200
      body.should have_tag('form[action="/parsers"]') do
        with_tag('textarea#names')
        with_tag('input[value="Submit"]')
      end
    end
  end
  
  describe 'create' do
    it 'should render json' do
      visit("/parsers?names=#{URI.encode "Betula pubescens|Plantago major L. 1786"}&format=json")
      page.status_code == 200
      JSON.load(body).size.should == 2
      body.should include('"parsed":true')
    end
    
    it 'should render html' do
      visit("/parsers?names=#{URI.encode "Betula pubescens|Plantago major L. 1786"}&format=html")
      page.status_code == 200
      body.should include('<span class="tree_key">parsed: </span>true')
    end
  end
end
