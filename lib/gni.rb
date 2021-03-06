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
    #  plotting in R
    #> a <- c(-10, -9, -8, -7, -6, -5, -4, -3,
    #    -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    #> b = atan(a * a**2) * 50/(pi*0.5) + 50
    #> plot(a,b)
    #> text(a,b, round(b,2), pos = 4, cex=1.3, las = 2, col='blue')

    num = num.to_f
    Math.atan(num * num**2) * 0.5/(Math::PI*0.5) + 0.5
  end

  def self.version_to_int(version)
    coeff = 1
    res = 0
    version_ary = version.split(".")
    until version_ary.empty?
      num = version_ary.pop.to_i
      res += coeff * num
      coeff *= 100
    end
    res
  end

  def self.cleanup
    resolver_dir = Rails.root.join('tmp', 'name_resolvers').to_s
    %x(find #{resolver_dir} -name *_* -maxdepth 0 -mtime 1 -exec rm -rf {} \\\;)
    NameResolver.connection.execute("
      delete 
      from name_resolvers 
      where updated_at < '%s'" % 1.day.ago.to_s)
  end
end
