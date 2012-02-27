class CreateExternalListReconcilers < ActiveRecord::Migration
  def change
    create_table :external_list_reconcilers do |t|
      t.text :data
      t.string :options
      t.references :progress_status
      t.string :progress_message

      t.timestamps
    end
    add_index :external_list_reconcilers, :progress_status_id
  end
end
