require File.dirname(__FILE__) + '/../spec_helper'

describe 'Parser' do
  before :all do
    @parser = Parser.new
    @parser_version = ScientificNameParser::VERSION
  end

  it 'should parse a name' do
    r = @parser.parse "Betula verucosa"
    r.should_not be_nil
    r.should == {:scientificName=>{:parsed=>true, :positions=>{0=>["genus", 6], 7=>["species", 15]}, :verbatim=>"Betula verucosa", :details=>[{:species=>{:string=>"verucosa"}, :genus=>{:string=>"Betula"}}], :hybrid=>false, :parser_version=> @parser_version, :normalized=>"Betula verucosa", :canonical=>"Betula verucosa", :parser_run=>1}}
  end

  it 'should returnd parsed false for names it cannot parse' do
    r = @parser.parse "this is a bad name"
    r.should_not be_nil
    r.should == {:scientificName=>{:parsed=>false, :verbatim=>"this is a bad name", :parser_version => @parser_version}}
  end

  it 'should convert parsed result to html' do
    r = @parser.parse "Betula verucosa"
    r.format_html.should include('span class')
  end

  it 'should convert parsed result to json' do
    r = @parser.parse "Betula verucosa"
    r.format_json.should include "{\"scientificName\""
  end

  it 'should parse names_list' do
    r = @parser.parse_names_list("Betula verucosa\nHomo sapiens")
    JSON.load(r).should == [{"scientificName"=>{"parser_run"=>1, "parsed"=>true, "verbatim"=>"Betula verucosa", "parser_version"=>"3.1.2", "canonical"=>"Betula verucosa", "hybrid"=>false, "normalized"=>"Betula verucosa", "positions"=>{"7"=>["species", 15], "0"=>["genus", 6]}, "details"=>[{"genus"=>{"string"=>"Betula"}, "species"=>{"string"=>"verucosa"}}]}}, {"scientificName"=>{"parser_run"=>1, "parsed"=>true, "verbatim"=>"Homo sapiens", "parser_version"=>"3.1.2", "canonical"=>"Homo sapiens", "hybrid"=>false, "normalized"=>"Homo sapiens", "positions"=>{"5"=>["species", 12], "0"=>["genus", 4]}, "details"=>[{"genus"=>{"string"=>"Homo"}, "species"=>{"string"=>"sapiens"}}]}}] 
    r = @parser.parse_names_list("Betula verucosa\nHomo sapiens",'xml')
    r.should include('xml version')
    r = @parser.parse_names_list("Betula verucosa\nHomo sapiens",'yaml')
    r.should include("canonical: Betula verucosa")
  end
end
