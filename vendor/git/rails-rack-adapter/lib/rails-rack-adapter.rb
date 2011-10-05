$:.unshift File.dirname(__FILE__)

require 'rubygems'

begin
  require 'rack'
rescue LoadError
  raise "rack is required for rails-rack-adapter, try: gem install rack"
end

module Rack
  module Handler
    autoload :Thin, 'rack/handler/thin'
  end
  module Adapter
    autoload :Rails, 'rack/adapter/rails'
  end
end
