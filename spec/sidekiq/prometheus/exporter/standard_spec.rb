# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidekiq::Prometheus::Exporter::Standard do
  describe '#to_s' do
    let(:exporter) { described_class.new }
    let(:stats) do
      instance_double(
        Sidekiq::Stats, processed: 10, failed: 9, workers_size: 8, enqueued: 7,
                        scheduled_size: 6, retry_size: 5, dead_size: 4
      )
    end
    let(:queues) do
      [
        instance_double(Sidekiq::Queue, name: 'default', size: 1, latency: 24.32109676),
        instance_double(Sidekiq::Queue, name: 'additional', size: 0, latency: 1.00200001)
      ]
    end
    let(:now) { Time.now }
    let(:workers) do
      [
        ['worker1:1:0493e4117adb', '2oe', {'queue' => 'default', 'run_at' => now.to_i - 10, 'payload' => {}}],
        ['worker1:1:0493e4117adb', '2si', {'queue' => 'default', 'run_at' => now.to_i - 20, 'payload' => {}}],
        ['worker2:1:dbf573ecf819', '2hi', {'queue' => 'additional', 'run_at' => now.to_i - 30, 'payload' => {}}],
        ['worker2:1:dbf573ecf819', '2s8', {'queue' => 'additional', 'run_at' => now.to_i - 40, 'payload' => {}}]
      ]
    end
    let(:metrics_text) do
      # rubocop:disable Layout/IndentHeredoc
      <<-TEXT
# HELP sidekiq_processed_jobs_total The total number of processed jobs.
# TYPE sidekiq_processed_jobs_total counter
sidekiq_processed_jobs_total 10

# HELP sidekiq_failed_jobs_total The total number of failed jobs.
# TYPE sidekiq_failed_jobs_total counter
sidekiq_failed_jobs_total 9

# HELP sidekiq_busy_workers The number of workers performing the job.
# TYPE sidekiq_busy_workers gauge
sidekiq_busy_workers 8

# HELP sidekiq_enqueued_jobs The total number of enqueued jobs.
# TYPE sidekiq_enqueued_jobs gauge
sidekiq_enqueued_jobs 7

# HELP sidekiq_scheduled_jobs The number of jobs scheduled for a future execution.
# TYPE sidekiq_scheduled_jobs gauge
sidekiq_scheduled_jobs 6

# HELP sidekiq_retry_jobs The number of jobs scheduled for the next try.
# TYPE sidekiq_retry_jobs gauge
sidekiq_retry_jobs 5

# HELP sidekiq_dead_jobs The number of jobs being dead.
# TYPE sidekiq_dead_jobs gauge
sidekiq_dead_jobs 4

# HELP sidekiq_queue_latency_seconds The amount of seconds between oldest job being pushed to the queue and current time.
# TYPE sidekiq_queue_latency_seconds gauge
sidekiq_queue_latency_seconds{name="default"} 24.321
sidekiq_queue_latency_seconds{name="additional"} 1.002

# HELP sidekiq_queue_enqueued_jobs The number of enqueued jobs in the queue.
# TYPE sidekiq_queue_enqueued_jobs gauge
sidekiq_queue_enqueued_jobs{name="default"} 1
sidekiq_queue_enqueued_jobs{name="additional"} 0

# HELP sidekiq_queue_max_processing_time_seconds The amount of seconds between oldest job of the queue being executed and current time.
# TYPE sidekiq_queue_max_processing_time_seconds gauge
sidekiq_queue_max_processing_time_seconds{name="default"} 20
sidekiq_queue_max_processing_time_seconds{name="additional"} 40
      TEXT
      # rubocop:enable Layout/IndentHeredoc
    end

    before do
      Timecop.freeze(now)

      allow(Sidekiq::Stats).to receive(:new).and_return(stats)
      allow(Sidekiq::Queue).to receive(:all).and_return(queues)
      allow(Sidekiq::Workers).to receive(:new).and_return(workers)
    end

    it { expect(exporter.to_s).to eq(metrics_text) }
  end
end