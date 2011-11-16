#!/usr/bin/env ruby
ENV["RAILS_ENV"] ||= 'production'
require File.expand_path("../../../config/environment", __FILE__)

ds = DataSource.create(title:"Diatoms")
# url = "file://"
# url += File.expand_path File.join('~/tmp/col.tar.gz')
url = "http://gnaclr.globalnames.org/files/e3b1908d-0e17-47f5-a9a0-7b1071007fe2/diatoms.tar.gz"
di = DwcaImporter.create(data_source:ds, url:url)
di.import
