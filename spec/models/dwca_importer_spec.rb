require 'spec_helper'

describe DwcaImporter do
  before :all do
    @ds = Factory("data_source")
    @url = "file://"
    @url += File.expand_path File.join(File.dirname(__FILE__), '..', 'files', 'data.tar.gz')
  end
  
  it "should create importer" do
    di = DwcaImporter.create(data_source: @ds, url: @url)
    di.import.should be_true
  end
end
