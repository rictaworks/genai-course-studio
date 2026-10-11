class CreateDiagnosticProbes < ActiveRecord::Migration[8.1]
  def change
    create_table :diagnostic_probes do |t|
      t.string :key, null: false
      t.string :outcome, null: false
      t.string :status, null: false, default: "pending"
      t.string :active_job_id
      t.string :error_code
      t.integer :worker_pid
      t.timestamps
    end
    add_index :diagnostic_probes, :key, unique: true
    add_check_constraint :diagnostic_probes, "outcome IN ('success', 'failure')", name: "probe_outcome"
    add_check_constraint :diagnostic_probes, "status IN ('pending', 'succeeded', 'failed')", name: "probe_status"
  end
end
