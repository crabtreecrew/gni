require File.dirname(__FILE__) + '/../spec_helper'

describe '/data_sources' do
  before :all do
    EolScenario.load :application
  end

  after :all do
    truncate_all_tables
    Capybara.reset_sessions!
  end

  describe 'without loging in' do

    it 'should render' do
      visit(data_sources_path)
      page.status_code.should == 200
      body.should include("Scientific Names Repositories")
      body.should_not include("Your Repositories")
    end

    it 'should show a repository settings' do
      repo = DataSource.find_by_title('ITIS')
      visit(data_source_path(repo))
      page.status_code.should == 200
      body.should include("Repository &ldquo;ITIS&rdquo;")
      body.should_not include("Self-Harvesting")
    end

    it 'should not allow user to access form for creation of new repositories' do
      visit(new_data_source_path)
      page.current_path.should == data_sources_path
    end

    it 'should not allow user to create new repositories' do
      count = DataSource.count
      page.driver.post(data_sources_path,{ 'data_source[title]' => 'a title' })
      body.blank?.should  be_true
      DataSource.count.should == count
    end

    it 'should not allow user to update a repository' do
      new_title = 'new_title'
      page.driver.post(data_source_path(DataSource.last), { '_method' => 'put', 'data_source[title]' => new_title })
      body.blank?.should be_true
      DataSource.last.title.should_not == new_title
    end

    it 'should not allow user to delete a repository' do
      DataSource.gen
      count = DataSource.count
      page.driver.post(data_source_path(DataSource.last), { '_method' => 'delete' })
      DataSource.count.should == count
      body.blank?.should be_true
    end

    it 'should render search' do
      visit("/data_sources/1?search_term=ADN*")
      page.status_code.should == 200
      body.should include('Adnaria frondosa')
    end

  end

  describe '/data_sources with logging in' do

    before :all do
      @user = User.find_by_login('aaron')
      @repo = @user.data_sources.first
      @others_repo = DataSource.all.select {|ds| !@user.data_sources.include? ds}.first
    end

    before :each do
      login_as(:login => 'aaron', :password => 'monkey')
    end

    it 'should show your repositories' do
      visit(data_sources_path)
      body.should include("Scientific Names Repositories")
      body.should include("Your Repositories")
      body.should include("add new repository")
    end

    it 'should show users their repositories' do
      visit(data_source_path(@repo))
      page.status_code.should == 200
      body.should include("Repository &ldquo;#{@repo.title}&rdquo;")
      body.should include("Self-Harvesting")
    end

    it 'should show a form to create new repository' do
      visit("/data_sources/new")
      body.should have_tag('form[action="/data_sources"]') do
        with_tag('input#data_source_title')
        with_tag('input#data_source_data_url')
        with_tag('input#data_source_refresh_period_days')
        with_tag('textarea#data_source_description')
        with_tag('input#data_source_web_site_url')
        with_tag('input#data_source_logo_url')
        with_tag('input#data_source_submit[value="Create"]')
      end
    end

    it 'should be able to create a new repository' do
      count = DataSource.count
      visit(new_data_source_path)
      fill_in "data_source_title", :with => "New Title"
      fill_in "data_source_data_url", :with => "http://example.com/data.xml"
      fill_in "data_source_refresh_period_days", :with => 3
      click_button "Create" 
      page.current_path.should == data_source_path(DataSource.last)
      DataSource.count.should == count + 1
    end

    it 'should show an edit form for a repository' do
      visit(edit_data_source_path(@repo))
      page.status_code.should == 200
      body.should have_tag("form[action=?]", "/data_sources/#{@repo.id}") do
        with_tag('input') do
          '[value="put"]'
          '[name="_method"]'
        end
        with_tag('input#data_source_title')
        with_tag('input#data_source_data_url')
        with_tag('input#data_source_refresh_period_days')
        with_tag('textarea#data_source_description')
        with_tag('input#data_source_web_site_url')
        with_tag('input#data_source_logo_url')
        with_tag('input#data_source_submit[value="Update"]')
      end
    end

    it 'should be able to update their repository' do
      @repo.id.should == 1 #double check that it is a data_source with logo url
      new_description = "new description #{rand}"
      visit(edit_data_source_path(@repo))
      fill_in "data_source_description", :with => new_description
      click_button "Update"
      page.current_path.should == data_source_path(@repo)
      DataSource.find(@repo.id).description.should == new_description
    end

    it 'should be able to delete their repository' do
      new_repo = DataSource.gen
      DataSourceContributor.gen(:data_source_id => new_repo.id, :user_id => @user.id)
      count = DataSource.count
      page.driver.post(data_source_path(new_repo), {'_method' => 'delete'})
      DataSource.count.should == count - 1
    end

    it 'should not see edit form for others repositories' do
      visit(edit_data_source_path(@others_repo))
      page.current_path.should == data_sources_path
    end

    it 'should not be able to update others repositories' do
      new_description = "new description #{rand}"
      page.driver.post(data_source_path(@others_repo), {
        '_method' => 'put',
        'data_source[description]' => new_description
      })
      body.should == ''
      DataSource.find(@others_repo.id).description.should_not == new_description
    end

    it 'should not be able to delete others repositories' do
      count = DataSource.count
      page.driver.post(data_source_path(@others_repo), :params => {'_method' => 'delete'})
      DataSource.count.should == count
    end

    it 'should delete trailing spaces from urls during create (Bug TAX-196)' do
      count = DataSource.count
      visit(new_data_source_path)
      fill_in "data_source_title", :with => "Random title " + rand.to_s
      fill_in "data_source_data_url", :with => " http://data/data.xml "
      fill_in "data_source_logo_url", :with => "  http://url_logo/logo.gif "
      fill_in "data_source_web_site_url", :with => "      http://url_website/index.html "
      fill_in "data_source_refresh_period_days", :with =>'3'
      click_button "Create"
      page.current_path.should == data_source_path(DataSource.last)
      DataSource.count.should == count + 1
      ds = DataSource.last
      ds.data_url.should == 'http://data/data.xml'
      ds.logo_url.should == 'http://url_logo/logo.gif'
      ds.web_site_url.should == 'http://url_website/index.html'
    end

    it 'should delete trailing spaces from urls during update (Bug TAX-196)' do
      Faker
      visit(edit_data_source_path(@repo))
      fill_in "data_source_data_url", :with => "          http://data/data123.xml "
      fill_in "data_source_logo_url", :with => "     http://url_logo/logo123.gif "
      fill_in "data_source_web_site_url", :with => "         http://url_website123/index.html "
      click_button "Update"
      page.current_path.should == data_source_path(@repo)
      ds = DataSource.find(@repo.id)
      ds.data_url.should == 'http://data/data123.xml'
      ds.logo_url.should == 'http://url_logo/logo123.gif'
      ds.web_site_url.should == 'http://url_website123/index.html'
    end
  end

end
