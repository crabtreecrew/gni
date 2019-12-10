#! /bin/sh

# Resource: https://www.skcript.com/svr/dockerize-a-rails-app-with-mysql-and-sidekiq/

# Wait for DB services
sh ./config/docker/scripts/wait-for-services.sh

# Prepare DB (Migrate - If not? Create db & Migrate)
sh ./config/docker/scripts/prepare-db.sh

# Prepare solr
# sh ./config/docker/scripts/prepare-solr.sh

# Pre-comple app assets
# sh ./config/docker/scripts/assets-pre-compile.sh

# Start Application
# unicorn -c /app/config/docker/files/unicorn.rb
