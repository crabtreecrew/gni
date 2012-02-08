require 'net/http'
require 'rest_client'
require 'uri'

Dir[Rails.root.join("lib", "gni", "*.rb")].each {|f| require f}

module Gni
end
