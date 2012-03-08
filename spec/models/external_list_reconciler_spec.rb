# encoding: utf-8
require 'spec_helper'

describe ExternalListReconciler do
  before do 
    @file_names_with_ids = File.join(File.dirname(__FILE__), '..', 'files', 'names_with_ids.txt')
    @file_names = File.join(File.dirname(__FILE__), '..', 'files', 'names.txt')
    @file_names_latin1 = File.join(File.dirname(__FILE__), '..', 'files', 'names_latin1.txt')
    @file_test_names = File.join(File.dirname(__FILE__), '..', 'files', 'bird_names.txt')
    @names_with_ids = ExternalListReconciler.read_file(@file_names_with_ids)
    @names = ExternalListReconciler.read_file(@file_names)
    @names_latin1 = ExternalListReconciler.read_file(@file_names_latin1)
    @test_names = ExternalListReconciler.read_file(@file_test_names)
  end

  it "should be able to open files with names in pipe delimited list" do
    @names_with_ids[0].should == { :id => "2", :name_string => "Nothocercus bonapartei" }
    @names[0].should == { :id => nil, :name_string => "Nothocercus bonapartei" }
  end

  it "should be able to open files with names in tab delimited list" do
    @test_names[0].should == {:id=>"7", :name_string=>"Chaetomorpha linum (O.F. Müller) Kützing"}
  end

  it "should be able to convert latin1 lines to utf-8 on the fly" do
    @names_latin1[0].should == {:id => nil, :name_string => "Andrena anthrisci Blüthgen, 1925"} 
    @names_latin1.each do |name_hash|
      name_hash[:name_string].encoding.to_s.should == "UTF-8"
      name_hash[:name_string].valid_encoding?.should be_true
    end
  end

  it "should be able to create and and find an instance" do
    elr = ExternalListReconciler.create(:options => { :with_context => false }, :data => @names_latin1)
    instance = ExternalListReconciler.find(elr.id)
    elr.should == instance
    elr.data.class.should == Array
    elr.data[0].should == { :id => nil, :name_string => "Andrena anthrisci Blüthgen, 1925" }
    elr.options.should == { :with_context => false, :with_parsed => false, :data_sources => [] }
  end

  it "should be able to reconcile names against one data_source" do
    elr = ExternalListReconciler.create(:options => {:data_sources => [1,3]}, :data => @test_names)
    elr.reconcile 
  end

  
end
