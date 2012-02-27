class Reconciler < ActiveRecord::Base
  has_many :reconciler_data_sources
  has_many :reconciler_batches
  has_many :data_sources, :through => :reconciler_data_sources

  @queue = :reconciler

  scope :in_data_sources, 

  def self.perform(reconciler_id)
    r = Reconciler.find(reconciler_id)
    r.reconcile
  end

  def reconcile(opts = {})
    opts = { :with_lexical_groups_match => false }.merge(opts)
    batch = next_batch
    while batch
      matches, non_matches = exact_match(batch.name_strings)
      if no_matches 
        fuzzy_match(non-matches) 
      end
      batch = next_batch
    end
  end

  def exact_match(name_strings)
    match = []
    no_match = []
    res = nil
    name_strings.each do |name_string|
      res = NameString.where(:normalized => Taxamatch::Normalizer.normalize(name_string)).limit(1)
      if res
        match << res[0]
      else
        no_match << name_string 
      end
    end
    [match, no_match]
  end

  def reconciliation_match
  end

  def fuzzy_match(name_strings)
    namestrings.each do |name_string|
      name_string.reconcile
    end
  end

  def next_batch
    transaction do
      batch = r.reconciler_batches.where(:status => ReconcilerBatch::STATUS_NULL).limit(1).to_sql
      if batch
        batch.status = ReconcilerBatch::STATE_PROGRESS
        batch.save!
      end
    end
    batch
  end

  def create_batches
    delete_batches
    count = 0
    if data_sources.blank?
      count = NameString.count
    else
      count = NameString.connection.select_value("select count(distinct ns.id) from name_strings ns join name_string_indices nsi on nsi.name_string_id = ns.id where nsi.data_source_id in (1, 2)")
    end
    offset = 0
    while offset < count
      ReconcilerBatch.create(:reconciler => self, :offset => offset, :status => ReconcilerBatch::STATUS_NULL)
      offset += batch_size
    end
  end
  
  def delete_batches
    NameString.connection.execute("delete from reconciler_batches where reconciler_id = %s" % self.id)
  end

end
