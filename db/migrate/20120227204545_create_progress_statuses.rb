class CreateProgressStatuses < ActiveRecord::Migration
  def change
    create_table :progress_statuses do |t|
      t.string :name

      t.timestamps
    end
  end
end
