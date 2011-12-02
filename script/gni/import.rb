#!/usr/bin/env ruby
ENV["RAILS_ENV"] ||= 'production'
require File.expand_path("../../../config/environment", __FILE__)

ds = DataSource.find(18)
# url = "file://"
# url += File.expand_path File.join('~/tmp/col.tar.gz')
url = "http://gnaclr.globalnames.org/files/39fcad53-f6b6-437e-8063-df18abff2319/index_fungorum.tar.gz"
di = DwcaImporter.create(data_source:ds, url:url)
di.import
