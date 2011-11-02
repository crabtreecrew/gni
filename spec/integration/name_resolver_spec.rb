require File.dirname(__FILE__) + '/../spec_helper'

describe '/name_resolver' do

  before :all do
    EolScenario.load :application
    @url = lambda { |format, with_canonical_forms| URI.encode "/name_resolver.#{format}?names=Betula alba|Parus major&data_sources=1|2&with_canonical_forms=#{with_canonical_forms}" }
  end

  it 'should render xml' do
    visit(@url.call("xml", "false"))
    page.status_code.should == 200
    body.should have_tag('name_string')
    body.should include('<?xml')
  end

  it 'should render yaml' do
    visit(@url.call("yaml", "true"))
    page.status_code.should == 200
    body.should include('name_string:')
    body.should include('---')
  end

  it 'should render json' do
    visit(@url.call("json", "1") + "&callback=my_callback")
    page.status_code.should == 200
    body.should include('"name_string"')
    body.should include('my_callback(')
  end


end

