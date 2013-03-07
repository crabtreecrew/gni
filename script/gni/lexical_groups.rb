#!/usr/bin/env ruby
# encoding: utf-8

ENV["RAILS_ENV"] ||= 'development'
require File.expand_path("../../../config/environment", __FILE__)

CanonicalForm.connection.select_rows("select id, name from canonical_forms order by id").each do |id, name|
  next if name.match('×')
  Resque.enqueue(Gni::SolrSpellchecker, id, name) if name.match(' ')
end
