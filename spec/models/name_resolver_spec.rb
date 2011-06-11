require File.dirname(__FILE__) + '/../spec_helper'

describe NameResolver do
  before :all do
    @resolver = NameResolver.new
    @data_source1 = Factory(:data_source)
    @data_source2 = Factory(:data_source)
    @name1 = Factory(:name_string, :name => "Betula alba L.")
    @name2 = Factory(:name_string, :name => "Betula alba Linn.")
    @lex_group = Factory(:lexical_group)
    Factory(:lexical_group_name_string, :lexical_group => @lex_group, :name_string => @name1)
    Factory(:lexical_group_name_string, :lexical_group => @lex_group, :name_string => @name2)
    Factory(:name_index, :data_source => @data_source1, :name_string => @name1)
    Factory(:name_index, :data_source => @data_source2, :name_string => @name2)
  end

  it "should reconcile a name" do
    data = @resolver.resolve([@name1.name], [@data_source2.id])
    data.size.should == 1
    data[0].keys.should == ["data_source_id", "name_string_id", "data_source_name", "search_name_string", "name_string"]
    data[0]['name_string'].should == 'Betula alba Linn.'
  end

  it "should reconcile multiple names agaist multiple data sources" do
    data = @resolver.resolve([@name1.name, @name2.name], [@data_source2.id, @data_source1.id])
    data.size.should == 4
    data[0].keys.should == ["data_source_id", "name_string_id", "data_source_name", "search_name_string", "name_string"]
    data[0]['name_string'].match(/Betula alba L/).should be_true
  end
end

