class NomenclaturalCodesController < ApplicationController
  # GET /nomenclatural_codes
  # GET /nomenclatural_codes.json
  def index
    @nomenclatural_codes = NomenclaturalCode.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => json_callback(@nomenclatural_codes.to_json, 
                                                  params[:callback]) }
      format.xml { render :xml => @nomenclatural_codes }
    end
  end

end
