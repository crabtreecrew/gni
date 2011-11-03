require File.dirname(__FILE__) + '/../spec_helper'

describe '/url_check' do
  it 'should return OK for existing url' do
    visit('/url_check.xml?url=http://cnn.com')
    page.status_code.should == 200
    body.should include('OK')
  end

  it 'should return "URL is NOT accessible" for invalid url' do
    visit('/url_check.xml?url=not_url')
    page.status_code.should == 200
    body.should include('URL is NOT accessible')
  end
end

