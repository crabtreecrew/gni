module ApplicationHelper
  def title(page_title, options={})
    content_for(:title, page_title.to_s)
  end
  def match_type(id)
    types = {
      1 => "exact match",
      2 => "exact canonical match",
      3 => "fuzzy canonical match",
      4 => "exact canonical match (species level)",
      5 => "fuzzy canonical match (species level)",
      6 => "exact canonical match (genus level)"
    }
    types[id]
  end
end
