# encoding: utf-8
require 'spec_helper'

describe ExternalListReconciler do
  before do 
    @file_names_with_ids = File.join(File.dirname(__FILE__), '..', 'files', 'names_with_ids.txt')
    @file_names = File.join(File.dirname(__FILE__), '..', 'files', 'names.txt')
    @file_names_latin1 = File.join(File.dirname(__FILE__), '..', 'files', 'names_latin1.txt')
    @names_with_ids = ExternalListReconciler.read_file(@file_names_with_ids)
    @names = ExternalListReconciler.read_file(@file_names)
    @names_latin1 = ExternalListReconciler.read_file(@file_names_latin1)
  end

  it "should be able to open files with names" do
    @names_with_ids[0].should == { :id => "2", :name_string => "Nothocercus bonapartei" }
    @names[0].should == { :id => nil, :name_string => "Nothocercus bonapartei" }
  end

  it "should be able to convert latin1 lines to utf-8 on the fly" do
    @names_latin1[0].should == {:id=>nil, :name_string=>"Andrena anthrisci Blüthgen, 1925"} 
    @names_latin1.each do |name_hash|
      name_hash[:name_string].encoding.to_s.should == "UTF-8"
      name_hash[:name_string].valid_encoding?.should be_true
    end
  end

  it "should be able to create and and find an instance" do
    elr = ExternalListReconciler.create(:options => {}, :data => @names_latin1.to_json)
    instance = ExternalListReconciler.find(elr.id)
    elr.should == instance
  end

  it "should be able to reconcile names against one data_source" do
    elr = ExternalListReconciler.create(:options => {}, :data => @names_latin1.to_json)
    elr.reconcile 
  end
end
