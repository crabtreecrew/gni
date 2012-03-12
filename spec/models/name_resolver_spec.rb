# encoding: utf-8
require 'spec_helper'

describe NameResolver do
  before do 
    @file_names_with_ids = File.join(File.dirname(__FILE__), '..', 'files', 'names_with_ids.txt')
    @file_names = File.join(File.dirname(__FILE__), '..', 'files', 'names.txt')
    @file_names_latin1 = File.join(File.dirname(__FILE__), '..', 'files', 'names_latin1.txt')
    @file_test_names = File.join(File.dirname(__FILE__), '..', 'files', 'bird_names.txt')
    @file_score_names = File.join(File.dirname(__FILE__), '..', 'files', 'score_names.txt')
    @names_with_ids = NameResolver.read_file(@file_names_with_ids)
    @names = NameResolver.read_file(@file_names)
    @names_latin1 = NameResolver.read_file(@file_names_latin1)
    @test_names = NameResolver.read_file(@file_test_names)
    @score_names = NameResolver.read_file(@file_score_names)
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
    elr = NameResolver.create(:options => { :with_context => false }, :data => @names_latin1)
    instance = NameResolver.find(elr.id)
    elr.should == instance
    elr.data.class.should == Array
    elr.data[0].should == { :id => nil, :name_string => "Andrena anthrisci Blüthgen, 1925" }
    elr.options.should == { :with_context => false, :with_parsed => false, :data_sources => [] }
  end

  it "should be able to reconcile names against one data_source" do
    elr = NameResolver.create(:options => {:data_sources => [1,3]}, :data => @test_names)
    elr.reconcile 
    elr.data.select{|d| d.has_key?(:results)}.size.should > 0
  end
  
  it "should correctly place scores" do
    elr = NameResolver.create(:options => {:data_sources => [1,3]}, :data => @score_names)
    elr.reconcile 
    elr.data.select{|d| d.has_key?(:results)}.size.should > 0
    d = elr.data
    #UNINOMIALS
    #uninomial exact string match of 2 canonicals
    d[0][:results][0][:prescore].should == "1|0|2"
    d[0][:results][0][:score].should == 0.9882161311296586
    #uninomial exact string match with authorships
    d[1][:results][0][:prescore].should == "4|0|2"
    d[1][:results][0][:score].should == 0.9985263536479112
    #uninomial exact canonical match without authorship
    d[2][:results][0][:prescore].should == "1|0|2"
    d[2][:results][0][:score].should == 0.9882161311296586
    #uninomial exact canonical match with authorship
    d[3][:results][0][:prescore].should == "1|2|2"
    d[3][:results][0][:score].should == 0.9974535752333309
    #uninomial fuzzy canonical match both canonicals
    d[4][:results][0][:prescore].should == "0|0|2"
    d[4][:results][0][:score].should == 0.9604165758394345
    #uninomial fuzzy canonical match one with authorship
    d[5][:results][0][:prescore].should == "0|0|2"
    d[5][:results][0][:score].should == 0.9604165758394345
    #uninomial fuzzy canonical match with authorhsips
    d[6][:results][0][:prescore].should == "0|2|2"
    d[6][:results][0][:score].should == 0.9950268127210495
    
    #BINOMIALS
    #binomial exact string match of 2 canonicals
    d[7][:results][0][:prescore].should == "3|0|4"
    d[7][:results][0][:score].should == 0.9990719854684394
    #binomial exact string match with authorships
    d[8][:results][0][:prescore].should == "8|0|4"
    d[8][:results][0][:score].should == 0.9998157929105035
    #binomial exact canonical match without authorship
    d[9][:results][0][:prescore].should == "3|0|4"
    d[9][:results][0][:score].should == 0.9990719854684394
    #binomial exact canonical match with authorship
    d[10][:results][0][:prescore].should == "3|2|4"
    d[10][:results][0][:score].should == 0.9995633611981729
    #binomial fuzzy canonical match both canonicals
    d[11][:results][0][:prescore].should == "2|0|4"
    d[11][:results][0][:score].should == 0.9985263536479112
    #binomial fuzzy canonical match one with authorship
    d[12][:results][0][:prescore].should == "2|0|4"
    d[12][:results][0][:score].should == 0.9985263536479112
    #binomial fuzzy canonical match with authorhsips
    d[13][:results][0][:prescore].should == "2|2|4"
    d[13][:results][0][:score].should == 0.9993783017940766

    #TRINOMIALS
    #trinomial exact string match of 2 canonicals
    d[14][:results][0][:prescore].should == "8|0|1"
    d[14][:results][0][:score].should == 0.9995633611981729
    #trinomial exact string match with authorships
    d[15][:results][0][:prescore].should == "8|0|1"
    d[15][:results][0][:score].should == 0.9995633611981729
    #trinomial exact canonical match without authorship
    d[16][:results][0][:prescore].should == "7|0|1"
    d[16][:results][0][:score].should == 0.9993783017940766
    #trinomial exact canonical match with authorship
    d[17][:results][0][:prescore].should == "7|2|1"
    d[17][:results][0][:score].should == 0.9996816902199195
    #trinomial fuzzy canonical match both canonicals
    d[18][:results][0][:prescore].should == "3|0|1"
    d[18][:results][0][:score].should == 0.9950268127210495
    #trinomial fuzzy canonical match one with authorship
    d[19][:results][0][:prescore].should == "3|0|1"
    d[19][:results][0][:score].should == 0.9950268127210495
    #trinomial fuzzy canonical match with authorhsips
    d[20][:results][0][:prescore].should == "3|2|1"
    d[20][:results][0][:score].should == 0.9985263536479112


  end
  
end
