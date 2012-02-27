class ReconcilerBatch < ActiveRecord::Base
  belongs_to :reconciler
  belongs to :progress_status

  def name_strings
    data_source_ids = reconciler.data_sources.map(&:id).join(",")
    if data_source_ids.blank?
      NameString.find_by_sql.("select ns.id, ns.name, cf.name from name_strings ns left outer join canonical_forms cf on cf.id = ns.canonical_form_id limit #{offset} #{reconciler.batch_size}")
    else
      NameString.find_by_sql("select distinct ns.id, ns.name, cf.name from name_strings ns left outer join canonical_forms cf on cf.id = ns.canonical_form_id join name_string_indices nsi on nsi.name_string_id = ns.id where nsi.data_source_id in (#{data_source_ids}) limit #{offset}, #{reconciler.batch_size}")
    end
  end
end
