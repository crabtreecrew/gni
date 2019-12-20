#! /bin/sh

# If the production database exists, migrate. Otherwise setup (create all databases and migrate)
bundle exec rake db:migrate 2>/dev/null || bundle exec rake db:create:all db:migrate
bundle exec rake db:migrate RAILS_ENV=production
bundle exec rake db:seed
bundle exec rake db:seed RAILS_ENV=production
echo "STARTUP.SH: done preparing databases"
