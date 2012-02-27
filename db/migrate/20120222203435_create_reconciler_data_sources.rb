class CreateReconcilerDataSources < ActiveRecord::Migration
  def change
    create_table :reconciler_data_sources do |t|
      t.references :reconciler
      t.references :data_source

      t.timestamps
    end
    add_index :reconciler_data_sources, :reconciler_id
    add_index :reconciler_data_sources, :data_source_id
  end
end
