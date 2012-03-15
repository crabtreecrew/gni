class NameResolversController < ApplicationController

  def index
    if params[:names]
      create
    end
  end

  def show
    resolver = NameResolver.find_by_token(params[:id])
    respond_to do |format|
      format.html {} 
      format.json { render :json => resolver.to_json }
      format.xml { render :xml => resolver.to_xml }
    end
  end

  def create
    new_data = get_data
    opts = get_opts
    token = Base64.urlsafe_encode64(UUID.create_v4.raw_bytes)[0..-3]
    status = ProgressStatus.working
    message = "Submitted"
    result = {
      :id => token, 
      :url => "%s/name_resolvers/%s" % [Gni::Config.base_url, token],
      :status => status,
      :message => message,
      :parameters => opts}
    resolver = NameResolver.create!(:data => new_data, :result => result, :options => opts, :progress_status => status, :progress_message => message, :token => token)
    
    if new_data.size < 500
      resolver.reconcile
    else
      resolver.progress_message = "In a que"
      resolver.save!
      Resque.enqueue(NameResolver, resolver.id)
    end

    respond_to do |format|
      format.html { redirect_to name_resolver_path(resolver) }
      format.json { render :json => json_callback(resolver.to_json, params[:callback]) }
      format.xml  { render :xml => resolver.to_xml }
    end

  end

  private

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
    opts
  end
end
