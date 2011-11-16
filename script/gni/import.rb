#!/usr/bin/env ruby
ENV["RAILS_ENV"] ||= 'production'
require File.expand_path("../../../config/environment", __FILE__)

ds = DataSource.create(title:"NCBI")
# url = "file://"
# url += File.expand_path File.join('~/tmp/col.tar.gz')
url = "http://gnaclr.globalnames.org/files/3666f5ad-ca51-449c-8bfa-2c26c096366f/ncbi.tar.gz"
di = DwcaImporter.create(data_source:ds, url:url)
di.import
