require 'net/http'
require 'rest_client'
require 'uri'
require 'fileutils'
require 'lingua/stemmer'

Dir[Rails.root.join("lib", "gni", "*.rb")].each { |f| require f }

module Gni
end
