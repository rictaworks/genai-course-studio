require "test_helper"
require "securerandom"

class ProbeTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    assert_instance_of ActiveJob::QueueAdapters::SolidQueueAdapter, ProbeJob.queue_adapter
    assert_equal "postgresql", ActiveRecord::Base.connection_db_config.adapter
  end

  test "migration replay preserves an existing fixture and applied versions" do
    probe = DiagnosticProbe.create!(key: "fixture-#{SecureRandom.uuid}", outcome: "success")
    snapshot = probe.reload.attributes
    context = ActiveRecord::Base.connection_pool.migration_context
    versions = context.get_all_versions
    2.times { context.migrate }
    assert_equal versions, context.get_all_versions
    assert_equal snapshot, probe.reload.attributes
  end

  test "a rolled back enqueue persists neither fixture nor queue job" do
    key = "fixture-#{SecureRandom.uuid}"
    job_id = nil
    DiagnosticProbe.transaction do
      probe = EnqueueProbe.call(key: key, outcome: "success")
      job_id = probe.active_job_id
      assert SolidQueue::Job.exists?(active_job_id: job_id)
      raise ActiveRecord::Rollback
    end
    assert job_id
    refute DiagnosticProbe.exists?(key: key)
    refute SolidQueue::Job.exists?(active_job_id: job_id)
  end

  test "committed fixture persists across independent PostgreSQL connections" do
    probe = DiagnosticProbe.create!(key: "fixture-#{SecureRandom.uuid}", outcome: "success")
    ActiveRecord::Base.connection_pool.with_connection do |main_connection|
      main_pid = main_connection.select_value("SELECT pg_backend_pid()")
      observed = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          [ connection.select_value("SELECT pg_backend_pid()"), DiagnosticProbe.find(probe.id).attributes ]
        end
      end.value
      refute_equal main_pid, observed.first
      assert_equal probe.reload.attributes, observed.last
    end
  end

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
