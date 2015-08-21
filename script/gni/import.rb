#!/usr/bin/env ruby
ENV["RAILS_ENV"] ||= 'production'
require 'uri'
require File.expand_path("../../../config/environment", __FILE__)

def process_file(file)
  ds = DataSource.create(title:file)
  #ds = DataSource.find(169)
  url = URI.encode("file://" + file)
  di = DwcaImporter.create(data_source:ds, url:url)
  di.import
  puts "*" * 80
end

one_file = ARGV[0]

if one_file && one_file != ''
  puts one_file
  process_file(one_file)
else
  files = `ls -S ~/files/ubio`.split("\n").reverse
  files.each do |file|
    file_path = "/home/dimus/files/ubio/" + file
    process_file(file_path)
  end
end
