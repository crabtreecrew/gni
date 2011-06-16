class NameResolver

  def resolve(names, data_source_ids, with_canonical_forms = false)
    names = quote_names(names)
    q = "select distinct ns.name as search_name_string, ns2.id name_string_id, ns2.name name_string, ni.data_source_id, ds.title as data_source_name  from name_strings ns join lexical_group_name_strings ln on ln.name_string_id = ns.id join lexical_groups lg on lg.id = ln.lexical_group_id join lexical_group_name_strings ln2 on lg.id = ln2.lexical_group_id join name_strings ns2 on ns2.id = ln2.name_string_id join name_indices ni on ni.name_string_id = ns2.id join data_sources ds on ds.id = ni.data_source_id where ns.name #{conditional(names)} and ni.data_source_id #{conditional(data_source_ids)}"
    if with_canonical_forms
      q_canonical = "select distinct cf.name as search_name_string, ns2.id name_string_id, ns2.name name_string, ni.data_source_id, ds.title as data_source_name  from canonical_forms cf join  name_strings ns on ns.canonical_form_id = cf.id join lexical_group_name_strings ln on ln.name_string_id = ns.id join lexical_groups lg on lg.id = ln.lexical_group_id join lexical_group_name_strings ln2 on lg.id = ln2.lexical_group_id join name_strings ns2 on ns2.id = ln2.name_string_id join name_indices ni on ni.name_string_id = ns2.id join data_sources ds on ds.id = ni.data_source_id where cf.name #{conditional(names)} and ni.data_source_id #{conditional(data_source_ids)}"
      q += " union #{q_canonical}"
    end
    NameString.connection.select_all(q)
  end

  private

  def conditional(data)
    raise "No data" if data.blank?
    if data.size == 1
      return "= #{data[0]}"
    else
      return "in (#{data.join(',')})"
    end
  end

  def quote_names(names)
    names.map do |name|
      NameString.connection.quote(name)
    end
  end

end
