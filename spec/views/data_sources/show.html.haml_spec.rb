require 'spec_helper'

describe "data_sources/show.html.haml" do
  before(:each) do
    @data_source = assign(:data_source, stub_model(DataSource))
  end

  it "renders attributes in <p>" do
    render
  end
end
