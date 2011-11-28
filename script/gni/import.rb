#!/usr/bin/env ruby
ENV["RAILS_ENV"] ||= 'production'
require File.expand_path("../../../config/environment", __FILE__)

ds = DataSource.create(title:"Cu*Star")
# url = "file://"
# url += File.expand_path File.join('~/tmp/col.tar.gz')
url = "http://gnaclr.globalnames.org/files/3f017f8f-06fc-4098-989b-1234254b9a02/custar.tar.gz"
di = DwcaImporter.create(data_source:ds, url:url)
di.import
