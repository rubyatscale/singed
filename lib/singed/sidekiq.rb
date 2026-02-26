# frozen_string_literal: true

module Singed
  module Sidekiq
    class ServerMiddleware
      include ::Sidekiq::ServerMiddleware

      def call(job_instance, job_payload, queue, &block)
        return block.call unless capture_flamegraph?(job_instance, job_payload)

        flamegraph(flamegraph_label(job_instance, job_payload), &block)
      end

      private

      TRUTHY_STRINGS = %w[true 1 yes].freeze

      def capture_flamegraph?(job_instance, job_payload)
        return job_payload["x-singed"] if job_payload.key?("x-singed")

        job_class = self.job_class(job_instance, job_payload)
        return job_class.capture_flamegraph?(job_payload) if job_class.respond_to?(:capture_flamegraph?)

        TRUTHY_STRINGS.include?(ENV.fetch("SINGED_MIDDLEWARE_ALWAYS_CAPTURE", "false"))
      end

      def flamegraph_label(job_instance, job_payload)
        [job_class(job_instance, job_payload), job_payload["jid"]].compact.join("--")
      end

      def job_class(job_instance, job_payload)
        job_class = job_payload.fetch("wrapped", job_instance) # ActiveJob
        return job_class if job_class.is_a?(Class)
        return job_class.class if job_class.is_a?(::Sidekiq::Job)
        return job_class.constantize if job_class.respond_to?(:constantize)

        Object.const_get(job_class.to_s)
      end
    end
  end
end
