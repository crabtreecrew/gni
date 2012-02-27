class CreateReconcilers < ActiveRecord::Migration
  def change
    create_table :reconcilers do |t|
      t.integer :batch_size, :default => 10_000
      t.timestamps
    end
  end
end
