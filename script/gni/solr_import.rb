#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= 'production'
require File.expand_path("../../../config/environment", __FILE__)

[Gni::SolrCoreCanonicalForm.new, Gni::SolrCoreCanonicalFormIndex.new].each do |core|
  si = Gni::SolrIngest.new(core)
  si.ingest
end
