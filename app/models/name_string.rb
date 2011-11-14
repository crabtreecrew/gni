class NameString < ActiveRecord::Base
  def self.normalize(nstring)
    nstring.gsub(/\s{2,}/, ' ').strip
  end
end
