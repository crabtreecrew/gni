source "http://rubygems.org"
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.

gem "rails", "= 2.3.4"
gem "nokogiri"
gem "haml"
gem "sass"
gem "will_paginate", ">= 2.3.2"
gem "json"
gem "biodiversity", ">= 0.7.3"
gem "taxamatch_rb", ">= 0.6.4"

group :production do
  gem "newrelic_rpm"
end

group :development do
  gem "mysql" #mysql is in a weird place in production, skipping...
  gem "rmagick" #rmagic has to be old to work
  gem "rspec", "~> 1.3.0"
  gem "rspec-rails", "~> 1.3.2"
  gem "ruby-debug"
  gem "capybara", "0.3.9"
  gem "factory_girl"
  gem "faker"
  gem "eol_scenarios"
  gem "eol_rackbox"
end
