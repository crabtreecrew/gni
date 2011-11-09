require 'spec_helper'

describe "data_sources/index.html.haml" do
  before(:each) do
    assign(:data_sources, [
      stub_model(DataSource),
      stub_model(DataSource)
    ])
  end

  it "renders a list of data_sources" do
    render
  end
end
