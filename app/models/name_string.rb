class NameString < ActiveRecord::Base
  belongs_to :canonical_form
  has_many :canonical_forms
  def self.normalize(nstring)
    nstring.gsub(/\s{2,}/, ' ').strip
  end
end
