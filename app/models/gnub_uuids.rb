class GnubUuid < ActiveRecord::Base
  def path
    path = parent_id ? construct_path([parend_id]) : []
    path << id
    path.map { |u| NameString.parse_uuid(u,[]) }
  end

  private

  def construct_path(path)
    path
  end
end

