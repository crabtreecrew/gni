require File.dirname(__FILE__) + '/../spec_helper'

describe NameResolver do
  before :all do
    truncate_all_tables
    @resolver = NameResolver.new
    @data_source1 = Factory(:data_source)
    @data_source2 = Factory(:data_source)
    @data_source3 = Factory(:data_source)
    canonical_form = CanonicalForm.find_by_name('Betula alba') || Factory(:canonical_form, :name => 'Betula alba')
    @name1 = Factory(:name_string, :name => "Betula alba L.", :canonical_form => canonical_form)
    @name2 = Factory(:name_string, :name => "Betula alba Linn.", :canonical_form => canonical_form)
    @lex_group = Factory(:lexical_group)
    Factory(:lexical_group_name_string, :lexical_group => @lex_group, :name_string => @name1)
    Factory(:lexical_group_name_string, :lexical_group => @lex_group, :name_string => @name2)
    Factory(:name_index, :data_source => @data_source1, :name_string => @name1)
    Factory(:name_index, :data_source => @data_source2, :name_string => @name2)
  end

  it "should reconcile a name" do
    data = @resolver.resolve([@name1.name], [@data_source2.id])
    data.size.should == 1
    data[0].keys.sort.should == ["data_source_id", "name_string_id", "data_source_name", "search_name_string", "name_string"].sort
    data[0]['name_string'].should == 'Betula alba Linn.'
  end

  it "should reconcile a canonical name" do
    data = @resolver.resolve(['Betula alba'], [@data_source2.id], true)
    data.size.should == 1
    data[0].keys.sort.should == ["data_source_id", "name_string_id", "data_source_name", "search_name_string", "name_string"].sort
    data[0]['name_string'].should == 'Betula alba Linn.'
  end

  it "should reconcile multiple names agaist multiple data sources" do
    data = @resolver.resolve([@name1.name, @name2.name], [@data_source2.id, @data_source1.id])
    data.size.should == 4
    data[0].keys.sort.should == ["data_source_id", "name_string_id", "data_source_name", "search_name_string", "name_string"].sort
    data[0]['name_string'].match(/Betula alba L/).should be_true
  end

  it "should reconcile multiple names with canonicals agaist multiple data sources" do
    data = @resolver.resolve(['Betula alba', @name2.name], [@data_source2.id, @data_source1.id], true)
    data.size.should == 4
    data[0].keys.sort.should == ["data_source_id", "name_string_id", "data_source_name", "search_name_string", "name_string"].sort
    data[0]['name_string'].match(/Betula alba L/).should be_true
  end
end

