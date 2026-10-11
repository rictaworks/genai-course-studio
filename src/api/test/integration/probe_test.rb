require "test_helper"
require "securerandom"

class ProbeTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test "durable duplicate suppression and separate worker success and failure" do
    %w[success failure].each do |outcome|
      key = "fixture-#{SecureRandom.uuid}"
      first, second = 2.times.map { Thread.new { ActiveRecord::Base.connection_pool.with_connection { EnqueueProbe.call(key: key, outcome: outcome) } } }.map(&:value)
      assert_equal first.id, second.id
      assert_equal 1, SolidQueue::Job.where(active_job_id: first.active_job_id).count
      # A separate bin/jobs process must already be running against this test DB.
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
      until %w[succeeded failed].include?(first.reload.status)
        flunk "separate worker did not finish within 30 seconds" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        sleep 0.2
      end
      assert_equal(outcome == "success" ? "succeeded" : "failed", first.status)
      assert first.worker_pid
      refute_equal Process.pid, first.worker_pid
      assert_equal(outcome == "failure" ? "fixture_failure" : nil, first.error_code)
      if outcome == "failure"
        job = SolidQueue::Job.find_by!(active_job_id: first.active_job_id)
        until SolidQueue::FailedExecution.exists?(job_id: job.id)
          flunk "failed execution was not persisted" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
          sleep 0.1
        end
      end
      assert_equal first.id, EnqueueProbe.call(key: key, outcome: outcome).id
    end
  end
end
