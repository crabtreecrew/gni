class CreateReconcilerBatches < ActiveRecord::Migration
  def change
    create_table :reconciler_batches do |t|
      t.references :reconciler
      t.integer :offset
      t.integer :status

      t.timestamps
    end
    add_index :reconciler_batches, :reconciler_id
  end
end
