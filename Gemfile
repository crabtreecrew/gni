source "https://rubygems.org"
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.

gem "rails", "= 2.3.4"
gem "activerecord-mysql2-adapter"
gem "nokogiri"
gem "haml"
gem "sass"
gem "will_paginate", ">= 2.3.2"
gem "json"
gem "biodiversity", ">= 0.7.3"
gem "taxamatch_rb", ">= 0.6.4"
gem 'indifferent-variable-hash', :git => 'https://github.com/remi/indifferent-variable-hash'
gem "rmagick", '~> 2.13.2'  #rmagic has to be old to work

group :production do
  # gem "newrelic_rpm"
  gem "unicorn", "= 4.9.0"
end

group :development do
  gem "rspec", "~> 1.3.0"
  gem "rspec-rails", "~> 1.3.2"
  gem "ruby-debug"
  gem "capybara", "0.3.9"
  gem "factory_girl"
  gem "faker"
  gem "eol_scenarios"
  gem "eol_rackbox"
end
