require 'spec_helper'

describe DwcaImporter do
  before :all do
    @ds = Factory("data_source")
    @url = "file://"
    @url += File.expand_path File.join(File.dirname(__FILE__), '..', 'files', 'data.tar.gz')
  end
  
  it "should create importer" do
    jl_count = JobLog.count
    cf_count = CanonicalForm.count
    di = DwcaImporter.create(data_source: @ds, url: @url)
    di.import.should be_true
    require 'ruby-debug'; debugger
    (JobLog.count - jl_count).should > 0
    (CanonicalForm.count - cf_count).should > 0
    require 'ruby-debug'; debugger
    puts ''
  end

end
