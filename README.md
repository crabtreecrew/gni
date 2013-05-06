Global Names Index v.2
======================

[![Continuous Integration Status][1]][2]
[![Dependency Status][3]][4]

Indexes occurances of biological scientific names in the world, normalizes and
reconsiles lexical and taxonomic variants of the name strings.

Testing
-------

    rake db:drop:all
    rake db:create:all
    rake db:migrate
    rake db:migrate RAILS_ENV=test
    rake db:seed
    rake db:seed RAILS_ENV=test
    rake solr:start ( or rake solr:run in a separate terminal window)
    rake solr:build
    rspec

Also see .travis.yml org as an example

Working with seed data
----------------------

Use rake "db:seed RAILS_ENV=your_env" to populate tables in development,
test and production environments. Different environments differ in how and
which tables are populated. To add more data for testing/development
purposes use

    rake db:addnames

the command reads data from spec/files/addnames.csv to add more records
to the system.


Resolver worker
---------------

    RAILS_ENV=production RAKE_ENV=production QUEUE=name_resolver rake resque:work

Assets precompiling
-------------------

    bundle exec rake assets:precompile

Rebuilding canonical names index for production
-----------------------------------------------

  from the machine with solr go to gni dir and run

  rake db:solr:build RAILS_ENV=production

Copyright
---------

Authors: Dmitry Mozzherin, David Shorthouse

Copyright (c) 2012-2013 Marine Biological Laboratory. See LICENSE.txt for
further details.

[1]: https://secure.travis-ci.org/GlobalNamesArchitecture/gni.png
[2]: http://travis-ci.org/GlobalNamesArchitecture/gni
[3]: https://gemnasium.com/GlobalNamesArchitecture/gni.png
[4]: https://gemnasium.com/GlobalNamesArchitecture/gni
