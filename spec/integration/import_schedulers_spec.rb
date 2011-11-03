require File.dirname(__FILE__) + '/../spec_helper'

describe '/import_schedulers' do
  before :all do
    EolScenario.load :application
    EolScenario.load :import_scheduler
  end

  after :all do
    truncate_all_tables
  end

  describe 'index' do
    it 'should render' do
      visit('/import_schedulers.xml')
      page.status_code.should == 200
      body.should have_tag('refresh_period_days')
      visit('/import_schedulers.json')
      page.status_code.should == 200
      body.should include('"refresh_period_days":14,')
    end
  end

end
