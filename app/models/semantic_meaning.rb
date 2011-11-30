class SemanticMeaning < ActiveRecord::Base
  @cache = {}
  def self.method_missing(m, *args, &block)
    if @cache.blank?
      self.all.each {|sm| @cache[sm.name.to_sym] = sm.id}
    end
    if @cache[m]
      @cache[m]
    else 
      raise NoMethodError, "No method %s for %s" % [m, self.model_name]
    end
  end
end
