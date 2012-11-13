#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= 'development'
require File.expand_path("../../../config/environment", __FILE__)

class LexicalGroup
  def initialize
    @f = open('/Users/dimus/tmp/gni_species.txt')
    @spellchecker = Gni::SolrSpellchecker.new
  end

  def find
    w = open("/Users/dimus/tmp/gni_lexical_candidates", "a:utf-8")
    count = 0
    @f.each do |l|
      count += 1
      puts "record %s\n" % count if count % 100 == 0
      name = l.strip + "~"
      canonical_forms = @spellchecker.find(name)
      w.write("%s, %s\n\n" % [l, canonical_forms])
    end
  end
end

# lg = LexicalGroup.new
# lg.find

CanonicalForm.limit(10000).each do |cf|
  Resque.enqueue(Gni::SolrSpellchecker, cf.id, cf.name)
end
