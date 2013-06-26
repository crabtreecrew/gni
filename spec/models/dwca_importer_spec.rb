require 'spec_helper'

describe DwcaImporter do
  before :all do
    @ds = Factory("data_source")
    @url = "file://"
    @url_linnean = @url + File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'linnean.tar.gz'))
    @url_gnub = @url + File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'gnub.tar.gz'))

    @url += File.expand_path File.join(File.dirname(__FILE__), '..', 'files', 'data.tar.gz')
  end

  it "should create importer" do
    jl_count = JobLog.count
    cf_count = CanonicalForm.count
    di = DwcaImporter.create(data_source: @ds, url: @url)
    di.import.should be_true
    (JobLog.count - jl_count).should > 0
    (CanonicalForm.count - cf_count).should > 0
  end

  it "should create importer for data source with linnean clades" do
    jl_count = JobLog.count
    cf_count = CanonicalForm.count
    di = DwcaImporter.create(data_source: @ds, url: @url_linnean)
    di.import.should be_true
    (JobLog.count - jl_count).should > 0
    (CanonicalForm.count - cf_count).should > 0
    NameStringIndex.where(:data_source_id => @ds.id).select {|i| !i.classification_path.blank?}[0].classification_path == "Animalia|Arthropoda|Insecta|Diptera|Cecidomyiidae|Resseliella|Resseliella theobaldi"
  end

  it "should create importer for data source with gnub data" do
    jl_count = JobLog.count
    cf_count = CanonicalForm.count
    gnub_count = GnubUuid.count
    di = DwcaImporter.create(data_source: @ds, url: @url_gnub)
    di.import.should be_true
    (JobLog.count - jl_count).should > 0
    (CanonicalForm.count - cf_count).should > 0
    (GnubUuid.count - gnub_count).should > 0
  end
end
