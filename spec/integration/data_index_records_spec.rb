require File.dirname(__FILE__) + '/../spec_helper'

describe 'name_indices/1/name_index_records' do

  before :all do
    EolScenario.load :application
  end

  after :all do
    truncate_all_tables
  end

  it 'should render' do
    visit('/name_indices/1/name_index_records')
    page.status_code.should == 200
    body.should include('GUID')
    body.should include('Adnaria frondosa')
    body.should have_tag('table')
  end

end
