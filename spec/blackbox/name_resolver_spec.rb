require File.dirname(__FILE__) + '/../spec_helper'

describe '/name_resolver' do

  before :all do
    EolScenario.load :application
    @url = lambda { |format, with_canonical_forms| URI.encode "/name_resolver.#{format}?names=Betula alba|Parus major&data_sources=1|2&with_canonical_forms=#{with_canonical_forms}" }
  end

  it 'should render xml' do
    res = req(@url.call("xml", "false"))
    res.success?.should be_true
    res.body.should have_tag('name_string')
    res.body.should include('<?xml')
  end

  it 'should render yaml' do
    res = req(@url.call("yaml", "true"))
    res.success?.should be_true
    res.body.should include('name_string:')
    res.body.should include('---')
  end

  it 'should render json' do
    res = req(@url.call("json", "1") + "&callback=my_callback")
    res.success?.should be_true
    res.body.should include('"name_string"')
    res.body.should include('my_callback(')
  end


end
