class CreateJobLogs < ActiveRecord::Migration
  def change
    create_table :job_logs do |t|
      t.string :type
      t.integer :job_id
      t.string :message

      t.timestamps
    end
    add_index :job_logs, [:type, :job_id]
  end

end
