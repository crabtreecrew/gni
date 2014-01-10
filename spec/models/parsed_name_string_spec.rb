require 'spec_helper'

describe ParsedNameString do
  it "should reparse names from database" do
    NameString.where("parser_version < ?", Gni.version_to_int(ScientificNameParser.version)).size.should > 0
    ParsedNameString.reparse
    NameString.where("parser_version < ?", Gni.version_to_int(ScientificNameParser.version)).size.should == 0
    NameString.where(:parser_version => Gni.version_to_int(ScientificNameParser.version)).size.should == NameString.count
  end
end
