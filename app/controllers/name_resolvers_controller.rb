class NameResolversController < ApplicationController

  def index
    if params[:names]
      create(true)
    end
  end

  def show
    resolver = NameResolver.find_by_token(params[:id])
    respond_to do |format|
      present_result(format, resolver, true)
    end
  end

  def create(from_get = false)
    new_data = get_data
    opts = get_opts
    token = "_"
    while token.match(/_/) 
      token = Base64.urlsafe_encode64(UUID.create_v4.raw_bytes)[0..-3]
    end
    status = ProgressStatus.working
    message = "Submitted"

    data_sources = []
    opts[:data_sources].map do |ds_id| 
      ds_title = DataSource.find(ds_id).title.strip rescue nil
      data_sources << { :id => ds_id, :title => ds_title } if ds_title
    end

    result = {
      :id => token, 
      :url => "%s/name_resolvers/%s" % [Gni::Config.base_url, token],
      :data_sources => data_sources,
      :status => nil,
      :message => nil,
      :parameters => nil,
    }

    resolver = NameResolver.create!(
      :data => new_data, 
      :result => result, 
      :options => opts, 
      :progress_status => status, 
      :progress_message => message, 
      :token => token
    )

    if new_data.size < 500 || from_get
      resolver.reconcile
    else
      resolver.progress_message = "In a que" 
      resolver.save!
      Resque.enqueue(NameResolver, resolver.id)
    end
    respond_to do |format|
      present_result(format, resolver)
    end

  end

  private

  def present_result(format, resolver, is_show = false)
    @res = resolver.result
    @res[:url] += ".%s" % params[:format] if ['xml', 'json'].include?(params[:format])
    @res[:status] = resolver.progress_status.name
    @res[:message] = resolver.progress_message
    @res[:parameters] = resolver.options
    if is_show
      format.html
    else
      format.html { redirect_to name_resolver_path(resolver.token) }
    end
    format.json { render :json => json_callback(@res.to_json, params[:callback]) }
    format.xml  { render :xml => @res.to_xml }
  end

  def get_data
    new_data = nil
    if params[:data]
      new_data = NameResolver.read_data(params[:data].split("\n"))
    elsif params[:names]
      ids =  params[:local_ids] ? params[local_ids].split("|") : []
      names = params[:names].split("|")
      new_data = NameResolver.read_names(names, ids)
    elsif params[:file]
      new_data = NameResolver.read_file(params[:file])
    end
    new_data
  end

  def get_opts
    opts = {}
    opts[:with_context] = !!params[:with_context] == "true" if params.has_key?(:with_context)
    opts[:data_sources] = params[:data_source_ids].split("|").map { |i| i.to_i } if params[:data_source_ids]
    {:with_context => true, :data_sources => []}.merge(opts)
  end
end
