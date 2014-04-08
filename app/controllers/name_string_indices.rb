class NameStringIndicesController < ApplicationController

  respond_to :html, :json, :xml

  def index
    data_source_id = params[:data_source_id]
    local_id = params[:local_id]
    nsi = []
    if data_source_id && local_id
      @name_string_index = 
        NameStringIndex.
        where(data_source_id: data_source_id).
        where(local_id: local_id).limit(1)
    end
    respond_with(@name_string_index, location: @name_string_indices_url)
  end


end



