require File.dirname(__FILE__) + '/../spec_helper'

describe '/users' do
  before :all do
    EolScenario.load :application
  end

  after :all do
    truncate_all_tables
  end

  it 'should render /signup' do
    visit('/signup')
    page.status_code == 200
    body.should have_tag('form[action="/users"]') do
      with_tag 'input#user_login'
      with_tag 'input#user_email'
      with_tag 'input#user_password'
      with_tag 'input#user_password_confirmation'
      with_tag 'input[value="Sign Up"]'
    end
  end

  it 'should create new user' do
    count = User.count
    visit('/signup')
    fill_in "user_login", :with => "new_login"
    fill_in "user_email", :with => "new_login@example.com"
    fill_in "user_password", :with => 'secret'
    fill_in "user_password_confirmation", :with => 'secret'
    click_button "Sign Up"
    page.status_code.should == 200 #after redirection
    page.current_path.should == data_sources_path
    User.count.should == count + 1
  end

  it '/user/edit should render ' do
    user = User.find_by_login('aaron')
    visit(edit_user_path user)
    page.status_code.should == 200
    body.should have_tag('form[action=?]', "/users/#{user.id}") do
      with_tag 'input#user_email'
      with_tag 'input#user_password'
      with_tag 'input#user_password_confirmation'
      with_tag 'input[value="Save"]'
    end
  end

  it 'should update user' do
    user = User.find_by_login('aaron')
    visit(edit_user_path user)
    fill_in "user_email", :with => "updated@example.com"
    click_button "Save"
    page.status_code.should == 200 
    page.current_path.should == data_sources_path
    User.find_by_login('aaron').email.should == 'updated@example.com'
  end

end
