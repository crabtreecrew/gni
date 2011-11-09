require 'spec_helper'

describe "data_sources/new.html.haml" do
  before(:each) do
    assign(:data_source, stub_model(DataSource).as_new_record)
  end

  it "renders new data_source form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => data_sources_path, :method => "post" do
    end
  end
end
