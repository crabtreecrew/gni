class ApplicationController < ActionController::Base
  protect_from_forgery

  def json_callback(json_struct, callback)
    callback ? callback + "(" + json_struct + ");" : json_struct
  end

  def redirect_with_delay(url, delay = 0)
    @redirect_url, @redirect_delay = url, delay
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
end
