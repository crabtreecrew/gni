#!/usr/bin/env ruby
ENV["RAILS_ENV"] ||= 'production'
require File.expand_path("../../../config/environment", __FILE__)
# #Catalogue of Life
# ds = DataSource.create(title: "Catalogue of Life")
# url = "http://betula.mbl.edu/gna_test/catalogue_of_life/col.tar.gz"
# di = DwcaImporter.create(data_source:ds, url:url)
# di.import
# # Wikispecies
# ds = DataSource.create(title: "Wikispecies")
# url = "http://betula.mbl.edu/gna_test/wikispecies/dwca.tar.gz"
# di = DwcaImporter.create(data_source:ds, url:url)
# di.import
# # ITIS
# ds = DataSource.create(title: "ITIS")
# url = "http://betula.mbl.edu/gna_test/itis/dwca.tar.gz"
# di = DwcaImporter.create(data_source:ds, url:url)
# di.import
# # NCBI
# ds = DataSource.create(title: "NCBI")
# url = "http://betula.mbl.edu/gna_test/ncbi/dwca.tar.gz"
# di = DwcaImporter.create(data_source:ds, url:url)
# di.import
# # Index Fungorum
# ds = DataSource.create(title: "Index Fungorum")
# url = "http://gnaclr.globalnames.org/files/39fcad53-f6b6-437e-8063-df18abff2319/index_fungorum.tar.gz"
# di = DwcaImporter.create(data_source:ds, url:url)
# di.import
# #Green
# ds = DataSource.create(title: "GRIN Taxonomy of Plants")
# url = "http://gnaclr.globalnames.org/files/66dd0960-2d7d-46ee-a491-87b9adcfe7b1/grin_v4.tar.gz"
# di = DwcaImporter.create(data_source:ds, url:url)
# di.import
# # UNION
# ds = DataSource.create(title: "Union")
# url = "http://gnaclr.globalnames.org/files/51177d00-5bd2-012e-3ccb-4ee661f7029b/51177d00-5bd2-012e-3ccb-4ee661f7029b.tar.gz"
# di = DwcaImporter.create(data_source:ds, url:url)
# di.import
# # IRMNG
# ds = DataSource.create(title: "IRMNG")
# url = "http://gnaclr.globalnames.org/files/7157d628-36ed-4ca0-8797-8f3ed50a478b/irmng.tar.gz"
# di = DwcaImporter.create(data_source:ds, url:url)
# di.import
# # WoRMS
# ds = DataSource.create(title: "WoRMS")
# url = "http://betula.mbl.edu/gna_test/worms/dwca.tar.gz"
# di = DwcaImporter.create(data_source:ds, url:url)
# di.import
# #Freebase
# ds = DataSource.find_or_create_by_title("Freebase")
# url = "http://betula.mbl.edu/gna_test/freebase/dwca.tar.gz"
# di = DwcaImporter.create(data_source:ds, url:url)
# di.import
# # GBIF
# ds = DataSource.create(title: "GBIF")
# url = "http://betula.mbl.edu/gna_test/gbif/gbif.tar.gz"
# di = DwcaImporter.create(data_source:ds, url:url)
# di.import
# # GBIF
ds = DataSource.create(title: "EOL")
url = "http://betula.mbl.edu/gna_test/eol/dwca.tar.gz"
di = DwcaImporter.create(data_source:ds, url:url)
di.import
