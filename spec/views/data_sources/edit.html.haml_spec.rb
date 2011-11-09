require 'spec_helper'

describe "data_sources/edit.html.haml" do
  before(:each) do
    @data_source = assign(:data_source, stub_model(DataSource))
  end

  it "renders the edit data_source form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => data_sources_path(@data_source), :method => "post" do
    end
  end
end
