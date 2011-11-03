require File.dirname(__FILE__) + '/../spec_helper'

describe '/sessions' do
  before :all do
    EolScenario.load :application
  end

  after :all do
    truncate_all_tables
  end

  it 'should render' do
    visit('/login')
    page.status_code.should == 200
    body.should have_tag('form[action="/session"]') do
      with_tag('input#login')
      with_tag('input#password')
    end
  end

  it 'should display error message if credentials are wrong' do
    login_as(:login => 'wrong_user', :password => 'wrong_password')
    page.status_code.should == 200
    body.should have_tag('div#flash') do
      with_tag('span.error')
    end
    body.should include("Couldn't log you in as 'wrong_user'") #brittle
  end

  it 'should login aaron with password monkey' do
    visit('/login')
    fill_in "login", :with => 'aaron'
    fill_in "password", :with => 'monkey'
    click_button "Log in"
    page.current_path.should == data_sources_path #root_url did not work
  end

  it 'should be able to close session' do
    login_as(:login => 'aaron', :password => 'monkey')
    visit('/')
    body.should have_tag('span#current_user_login_name') #added tag only to simplify testing
    visit('/logout')
    visit('/')
    body.should_not have_tag('span#current_user_login_name')
  end


end
