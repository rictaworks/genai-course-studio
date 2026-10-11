class ProbeJob < ApplicationJob
  class FixtureFailure < StandardError; end
  queue_as :diagnostics
  def perform(id)
    probe = DiagnosticProbe.find(id)
    probe.with_lock do
      return unless probe.status == "pending"
      if probe.outcome == "failure"
        probe.update!(status: "failed", error_code: "fixture_failure", worker_pid: Process.pid)
      else
        probe.update!(status: "succeeded", worker_pid: Process.pid)
      end
    end
    raise FixtureFailure, "fixture_failure" if probe.status == "failed"
  end
end
