class ReconcilerDataSource < ActiveRecord::Base
  belongs_to :reconciler
  belongs_to :data_source
end
