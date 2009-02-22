class NameStringsController < ApplicationController
  layout "application", :except => :show
  
  # GET /name_strings
  # GET /name_strings.xml
  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 50
    search_term = params[:search_term].strip.gsub(/\*/,'%') rescue nil
    @char_triples = nil
    @names_total = Statistic.name_strings_count
    search_term_errors = validate_search_term(search_term)
    if search_term && search_term_errors.blank?
      if params[:commit] == 'Search Mine'
        @name_strings = NameString.paginate_by_sql(["select n.name from name_strings n join name_indices i on (n.id = i.name_string_id) join data_source_contributors c on (i.data_source_id = c.data_source_id)  where name like ? and c.user_id = ? order by n.name", search_term, current_user.id], :page => page, :per_page => per_page) || nil rescue nil
      elsif params[:data_source_id]
        search_term ||= '%'
        @name_strings = NameString.paginate_by_sql(["select n.* from name_strings n join name_indices i on (n.id = i.name_string_id) where name like ? and i.data_source_id = ? order by n.name", search_term, params[:data_source_id]], :page => page, :per_page => per_page) || nil rescue nil
      else
        @name_strings = NameString.paginate_by_sql(["select * from name_strings where name like ? order by name", search_term], :page => page, :per_page => per_page) || nil rescue nil 
      end
    else
      @name_strings = NameString.paginate_by_sql("select * from name_strings where 1=2", :page => page, :per_page => per_page) || nil rescue nil 
      flash[:error]=search_term_errors
    end    
    if params[:expand] && NameString::LATIN_CHARS.include?(params[:expand].strip)
      @char_triples = NameString.char_triples(params[:expand].strip)
    end
    result = {}
    result[:page_number] = page
    result[:name_strings_total] = @name_strings.total_entries rescue nil
    result[:total_pages] = (result[:name_strings_total]/(per_page.to_f)).ceil rescue 0
    result[:per_page] = per_page
    result[:data] = @name_strings
    
    respond_to do |format|
        format.html # index.html.erb
        format.xml {render :xml => result}
        format.json {render :json => result}
    end
  end

  # GET /name_strings/1
  # GET /name_strings/1.xml
  def show
    @name_string = NameString.find(params[:id])
    @data_sources_data = @name_string.name_indices.map {|ni| {:data_source => ni.data_source, :records => (NameIndexRecord.find_all_by_name_index_id(ni.id))}}
    data =  {:data => @data_sources_data, :name_string => @name_string}
    respond_to do |format|
      format.html #details.html.haml
      format.xml {render :xml => data}
      format.json {render :json => data}
    end
  end

protected

  def validate_search_term(search_term)
    errors = []
    if search_term
      errors << 'Search term with whild characters (* or %) should have at leat 3 letters' if (search_term.include?('%') && search_term.size < 4)
    end
    errors
  end
  
end
