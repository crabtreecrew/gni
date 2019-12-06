#! /bin/sh

bundle exec rake solr:start
bundle exec rake solr:build
echo "STARTUP.SH: done preparing solr"
