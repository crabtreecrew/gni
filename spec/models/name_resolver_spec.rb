# encoding: utf-8
require 'spec_helper'

describe NameResolver do
  before do
    @file_names_with_ids = File.join(File.dirname(__FILE__),
                                     '..',
                                     'files',
                                     'names_with_ids.txt')
    @file_names = File.join(File.dirname(__FILE__),
                            '..',
                            'files',
                            'names.txt')
    @file_names_latin1 = File.join(File.dirname(__FILE__),
                                   '..',
                                   'files',
                                   'names_latin1.txt')
    @file_test_names = File.join(File.dirname(__FILE__),
                                 '..',
                                 'files',
                                 'bird_names.txt')
    @file_score_names = File.join(File.dirname(__FILE__),
                                  '..',
                                  'files',
                                  'score_names.txt')
    @names_with_ids = NameResolver.read_file(@file_names_with_ids)
    @names = NameResolver.read_file(@file_names)
    @names_latin1 = NameResolver.read_file(@file_names_latin1)
    @test_names = NameResolver.read_file(@file_test_names)
    @score_names = NameResolver.read_file(@file_score_names)
  end

  it 'should be able to open files with names in pipe delimited list' do
    @names_with_ids[0].should == { id: '2',
                                   name_string: 'Nothocercus bonapartei' }
    @names[0].should == { id: nil, name_string: 'Nothocercus bonapartei' }
  end

  it 'should be able to open files with names in tab delimited list' do
    @test_names[0].should == { id: '7',
                      name_string: 'Chaetomorpha linum (O.F. Müller) Kützing' }
  end

  it 'should be able to convert latin1 lines to utf-8 on the fly' do
    @names_latin1[0].should == { id: nil,
                              name_string: 'Andrena anthrisci Blüthgen, 1925' }
    @names_latin1.each do |name_hash|
      name_hash[:name_string].encoding.to_s.should == "UTF-8"
      name_hash[:name_string].valid_encoding?.should be_true
    end
  end

  it 'should be able to create and and find an instance' do
    elr = NameResolver.create(options: { with_context: true },
                              data: @names_latin1,
                              token: SecureRandom.hex(16),
                              result: {url: 'something'})

    instance = NameResolver.find(elr.id)
    elr.should == instance
    elr.data.class.should == Array
    elr.data[0].should == { id: nil,
                            name_string: 'Andrena anthrisci Blüthgen, 1925' }
    elr.options.should == { with_context: true,
                            header_only: false,
                            best_match_only: false,
                            data_sources: [],
                            preferred_data_sources: [],
                            resolve_once: false }
  end

  it 'should be able to reconcile names against one data_source' do
    elr = NameResolver.create(options: { data_sources: [1,3] },
                              data: @test_names,
                              token: SecureRandom.hex(16),
                              result: {url: 'something'})
    elr.reconcile
    elr.data.select{|d| d.has_key?(:results)}.size.should > 0
  end

  it 'should create preferred results if asked' do
    elr = NameResolver.create(options: { preferred_data_sources: [1] },
                              data: @test_names,
                              token: SecureRandom.hex(16),
                              result: {url: 'something'})
    elr.reconcile
    elr.result[:data][11][:preferred_results].should_not be_nil
    elr.result[:data][11][:preferred_results].
      map { |r| r[:data_source_id] }.uniq.should == [1]
  end

end
