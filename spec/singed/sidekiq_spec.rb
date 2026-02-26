# frozen_string_literal: true

require "spec_helper"
require "sidekiq"
require "active_job"
require "singed/sidekiq"
require_relative "../support/sidekiq"

RSpec.describe Singed::Sidekiq::ServerMiddleware do
  subject { job_class.set(job_modifiers).perform_async(*job_args) }

  let(:job_class) { SidekiqPlainJob }
  let(:job_args) { [] }
  let(:job_modifiers) { {} }

  before do
    allow_any_instance_of(described_class).to receive(:flamegraph) { |*, &block| block.call }
    allow_any_instance_of(job_class).to receive(:perform).and_call_original
  end

  context "with plain Sidekiq jobs" do
    it "doesn't capture flamegraph by default" do
      expect_any_instance_of(described_class).not_to receive(:flamegraph)
      expect_any_instance_of(job_class).to receive(:perform)
      subject
    end

    context "when x-singed payload is true" do
      let(:job_modifiers) { {"x-singed" => true} }

      it "wraps execution in flamegraph when x-singed is true" do
        expect_any_instance_of(described_class).to receive(:flamegraph)
        expect_any_instance_of(job_class).to receive(:perform)
        subject
      end
    end
  end

  context "with class-level capture_flamegraph?" do
    let(:job_class) { SidekiqFlamegraphJob }

    it "doesn't capture when capture_flamegraph? returns false" do
      expect_any_instance_of(described_class).not_to receive(:flamegraph)
      expect_any_instance_of(job_class).to receive(:perform)
      subject
    end

    context "when payload satisfies capture_flamegraph?" do
      let(:job_modifiers) { {"x-flamegraph" => true} }

      it "wraps execution in flamegraph when capture_flamegraph? returns true" do
        expect_any_instance_of(described_class).to receive(:flamegraph)
        expect_any_instance_of(job_class).to receive(:perform)
        subject
      end
    end
  end

  context "when SINGED_MIDDLEWARE_ALWAYS_CAPTURE env var is set" do
    around do |example|
      original = ENV["SINGED_MIDDLEWARE_ALWAYS_CAPTURE"]
      example.run
    ensure
      if original.nil?
        ENV.delete("SINGED_MIDDLEWARE_ALWAYS_CAPTURE")
      else
        ENV["SINGED_MIDDLEWARE_ALWAYS_CAPTURE"] = original
      end
    end

    context "when SINGED_MIDDLEWARE_ALWAYS_CAPTURE=true" do
      before { ENV["SINGED_MIDDLEWARE_ALWAYS_CAPTURE"] = "true" }

      it "wraps execution in flamegraph" do
        expect_any_instance_of(described_class).to receive(:flamegraph)
        expect_any_instance_of(job_class).to receive(:perform)
        subject
      end
    end

    context "when SINGED_MIDDLEWARE_ALWAYS_CAPTURE is false" do
      before { ENV["SINGED_MIDDLEWARE_ALWAYS_CAPTURE"] = "false" }

      it "doesn't capture flamegraph" do
        expect_any_instance_of(described_class).not_to receive(:flamegraph)
        expect_any_instance_of(job_class).to receive(:perform)
        subject
      end
    end
  end

  context "with ActiveJob jobs" do
    subject { job_class.set(job_modifiers).perform_later(*job_args) }

    context "with plain ActiveJob" do
      let(:job_class) { ActiveJobPlainJob }

      it "doesn't capture flamegraph by default" do
        expect_any_instance_of(described_class).not_to receive(:flamegraph)
        expect_any_instance_of(job_class).to receive(:perform)
        subject
      end

      context "with ActiveJob class where capture_flamegraph? is true" do
        let(:job_class) { ActiveJobFlamegraphJob }

        it "wraps execution in flamegraph when capture_flamegraph? returns true" do
          expect_any_instance_of(described_class).to receive(:flamegraph)
          expect_any_instance_of(job_class).to receive(:perform)
          subject
        end
      end

      context "with ActiveJob class where capture_flamegraph? is false" do
        let(:job_class) { ActiveJobNoFlamegraphJob }

        it "doesn't capture when capture_flamegraph? returns false" do
          expect_any_instance_of(described_class).not_to receive(:flamegraph)
          expect_any_instance_of(job_class).to receive(:perform)
          subject
        end
      end

      context "when SINGED_MIDDLEWARE_ALWAYS_CAPTURE env var is set" do
        around do |example|
          original = ENV["SINGED_MIDDLEWARE_ALWAYS_CAPTURE"]
          example.run
        ensure
          if original.nil?
            ENV.delete("SINGED_MIDDLEWARE_ALWAYS_CAPTURE")
          else
            ENV["SINGED_MIDDLEWARE_ALWAYS_CAPTURE"] = original
          end
        end

        context "when SINGED_MIDDLEWARE_ALWAYS_CAPTURE=true" do
          before { ENV["SINGED_MIDDLEWARE_ALWAYS_CAPTURE"] = "true" }

          it "wraps execution in flamegraph" do
            expect_any_instance_of(described_class).to receive(:flamegraph)
            expect_any_instance_of(job_class).to receive(:perform)
            subject
          end
        end

        context "when SINGED_MIDDLEWARE_ALWAYS_CAPTURE is false" do
          before { ENV["SINGED_MIDDLEWARE_ALWAYS_CAPTURE"] = "false" }

          it "doesn't capture flamegraph" do
            expect_any_instance_of(described_class).not_to receive(:flamegraph)
            expect_any_instance_of(job_class).to receive(:perform)
            subject
          end
        end
      end
    end
  end
end
