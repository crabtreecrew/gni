#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= 'production'
require File.expand_path("../../../config/environment", __FILE__)

core = Gni::SolrCoreCanonicalForm.new
si = Gni::SolrIngest.new(core)

si.ingest
