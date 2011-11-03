require File.dirname(__FILE__) + '/../spec_helper'
require 'uri'

describe '/name_strings' do
  before :all do
    EolScenario.load :application
    EolScenario.load :name_string_search
  end

  after :all do
    truncate_all_tables
    Capybara.reset_sessions!
  end

  before(:each) do
    visit( name_strings_path )
    @resp = body
    page.status_code.should == 200
    visit(name_strings_path(:format => "xml"))
    @resp_xml = body
    page.status_code.should == 200
  end

  it 'should be used as a root path' do
    visit(root_path)
    @resp.should == body
  end

  it 'should have search box' do
    @resp.should have_tag('form[method=?]', 'get') do
      #search input
      with_tag('input[name=?]', 'search_term')
      #normal search button
      with_tag('input[name=?]', 'commit')
      with_tag('input[value=?]', 'Search')
      #without logging in -- no Search Mine button
      without_tag('input[value=?]', 'Search Mine')
    end
  end

  it 'should do search' do
    visit( URI.encode '/name_strings?search_term=Higehananomia Kôno 1935')
    body.should include("Higehananomia Kôno 1935")
  end

  it 'should do search with wildcard' do
    visit(name_strings_path, :search_term => "adna*")
    page.status_code.should == 200
    body.should include("Adnaria frondosa")
    body.should include("Adnatosphaeridium tutulosum (Cookson &amp; Eisenack 1960)")
    body.should_not include("Higehananomia palpalis")
  end

  it 'should be able to search a name with an apostrophy' do
    visit(name_strings_path, :search_term => "O'Connel")
    page.status_code.should == 200
    body.should include("Tauriaptychus crastobalensis (O'Connel )")
  end

  it 'should be able to search names with non-ascii characters' do
    visit(URI.encode "/name_strings?search_term=au:Kôno")
    page.status_code.should == 200
    body.should include("Higehananomia palpalis Kono 1935")
  end

  it 'API /hould return search in xml and json' do
    visit(name_strings_path, :format => "xml", :search_term => "adna*" )
    page.status_code.should == 200
    body.should include('<?xml version="1.0"')
    body.should include("Adnaria frondosa")
    body.should include("Adnatosphaeridium tutulosum (Cookson &amp; Eisenack 1960)")
    body.should_not include("Higehananomia palpalis")

    visit(name_strings_path(:format => "json", :search_term => "adna*"))
    page.status_code.should == 200
    body.should include("Adnaria frondosa")
    body.should include("Adnatosphaeridium tutulosum (Cookson \\u0026 Eisenack 1960)")
    body.should_not include("Higehananomia palpalis")
  end

  it 'should not search 2 or less chars with wildcard' do
    visit(name_strings_path(:search_term => "ad*"))
    page.status_code.should == 200
    body.should_not  include("Adnaria frondosa")
    body.should include("should have at leat 3 letters")
  end

  it 'should display a name_string page' do
    visit(name_string_path(1, :format => "xml"))
    page.status_code.should == 200
    body.should include('Adnaria frondosa')
    body.should_not have_tag('body')
  end

  it 'should redirect html page to a name_string "id"' do
    visit(name_string_path(1))
    page.current_path.should == "/name_strings/Adnaria_frondosa_(L.)_Kuntze"
  end

  it "Should be able to use name string as an id" do
    name_string = URI.encode("Adnaria frondosa (L.) Kuntze")
    visit("/name_strings/#{name_string}")
    page.status_code.should == 200
    body.should include('Adnaria frondosa')
  end

  it 'API should display a name_string info in xml or json' do
    visit(name_string_path(1, :format => "xml"))
    page.status_code.should == 200
    visit(name_string_path(1, :format => "xml", :all_records => 1))
    page.status_code.should == 200
    body.should include('<?xml version="1.0"')
    body.should include('Adnaria frondosa')
    visit(name_string_path(1, :format => "json"))
    page.status_code.should == 200
    body.should include('Adnaria frondosa')
  end
end
