class ApplicationController < ActionController::Base
  protect_from_forgery

  def json_callback(json_struct, callback)
    callback ? callback + "(" + json_struct + ");" : json_struct
  end
end
