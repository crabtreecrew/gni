require 'spec_helper'

describe Gni do 
  
  it "should calculate score" do
    nums = (-5..5)
    nums.map {|num| subject.num_to_score(num)}.should == [0.002546424766669053, 0.004973187278950408, 0.01178386887034144, 0.03958342416056554, 0.25, 0.5, 0.75, 0.9604165758394345, 0.9882161311296586, 0.9950268127210495, 0.9974535752333309]
  end

  it "should convert version to ineger" do
    versions = ['1.0.1', '2.8.12', '1.21.13']
    versions.map {|v| subject.version_to_int(v)}.should == [10001, 20812, 12113]
  end

end
