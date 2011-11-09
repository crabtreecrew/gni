require 'net/http'
require 'uri'

Dir[Rails.root.join("lib", "gni", "*.rb")].each {|f| require f}

module Gni
end
