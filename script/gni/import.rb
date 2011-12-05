#!/usr/bin/env ruby
ENV["RAILS_ENV"] ||= 'production'
require File.expand_path("../../../config/environment", __FILE__)
bad_files = open("bad_files.txt", "w")
files = `ls -S ~/DWCA`.split("\n").reverse
files.each do |file|
  ds = DataSource.create(title:file)
  # ds = DataSource.find(1)
  # url = "file://"
  # url += File.expand_path File.join('~/tmp/col.tar.gz')
  url = "file:///Users/dimus/DWCA/" + file.gsub(/\(/, "\\(").gsub(/\)/, "\\)")
  di = DwcaImporter.create(data_source:ds, url:url)
  di.import
end
