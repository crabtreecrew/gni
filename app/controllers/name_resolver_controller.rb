class NameResolverController < ApplicationController

  # GET /name_resolver
  def index
    data_sources = params[:data_sources].gsub("|", "\n")
    names = params[:names].gsub("|", "\n")
    resolve_names(names, data_sources)
  end

  private

  def resolve_names(names, data_sources)
    # result = NameResolver.resolve_names(names, data_sources)
    # if format == 'xml'
    #   render :xml => result
    # elsif format == 'yaml'
    #   render :text => result
    # elsif format == 'json'
    #   render :json => json_callback(result, params[:callback])
    # else
    #   @resolved_names = names
    #   render :action => :names
    # end
  end
end
