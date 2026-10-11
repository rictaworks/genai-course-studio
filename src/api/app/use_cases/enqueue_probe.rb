class EnqueueProbe
  def self.call(key:, outcome:)
    raise ArgumentError unless key.is_a?(String) && /\Afixture-[0-9a-f-]{36}\z/.match?(key) && %w[success failure].include?(outcome)
    DiagnosticProbe.transaction do
      probe = DiagnosticProbe.create_or_find_by!(key: key) { |record| record.outcome = outcome }
      probe.with_lock do
        unless probe.active_job_id
          job = ProbeJob.perform_later(probe.id)
          raise ActiveJob::EnqueueError, "enqueue_failed" unless job
          probe.update!(active_job_id: job.job_id)
        end
      end
      probe
    end
  end
end
