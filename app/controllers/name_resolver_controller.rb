class NameResolverController < ApplicationController

  # GET /name_resolver
  def index
    data_sources = params[:data_sources] ? params[:data_sources].gsub("|", "\n") : nil
    names = params[:names] ? params[:names].gsub("|", "\n") : ''
    result = resolve_names(names, data_sources)
    format = params[:format]
    if format == 'xml'
      render :xml => result.to_xml
    elsif format == 'yaml'
      render :text => result.to_yaml
    elsif format == 'json'
      render :json => json_callback(result.to_json, params[:callback])
    else
      @resolved_names = names
      render :action => :names
    end
  end

  private

  def resolve_names(names, data_source_ids)
    nr = NameResolver.new
    names = normalize(names)
    data_sources = get_data_sources(data_source_ids)
    result = nr.resolve(names, data_sources)
  end

  def normalize(data)
    data.split("\n").map { |ds| ds.gsub(/\s+/, ' ').strip }
  end

  def get_data_sources(data_source_ids)
    normalize(data_source_ids).map {|i| i.to_i}.uniq
  end

end
