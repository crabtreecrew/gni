require 'net/http'
require 'logger'
require 'rest_client'
require 'uri'
require 'fileutils'
require 'lingua/stemmer'

Dir[Rails.root.join("lib", "gni", "*.rb")].each { |f| require f }

module Gni
  
  def self.logger
    @@logger ||= Logger.new(nil)
  end

  def self.logger=(logger)
    @@logger = logger
  end

  def self.logger_reset
    self.logger = Logger.new(nil)
  end

  def self.logger_write(obj_id, message, method = :info)
    self.logger.send(method, "|%s|%s|" % [obj_id, message])
  end

  def self.num_to_score(num)
    num = num.to_f
    Math.atan(num * num**2) * 0.5/(Math::PI*0.5) + 0.5
  end

end
