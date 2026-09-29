# typed: strict
# frozen_string_literal: true

module Singed
  module Sidekiq
    class ServerMiddleware
      include ::Sidekiq::ServerMiddleware

      TRUTHY_STRINGS = %w(true 1 yes).freeze

      #: [Result] (::Sidekiq::Job, Hash[String, untyped], String) { () -> Result } -> Result
      def call(job_instance, job_payload, _queue, &block)
        return block.call unless capture_flamegraph?(job_instance, job_payload)

        flamegraph(flamegraph_label(job_instance, job_payload), &block)
      end

      private

      # A job class's capture_flamegraph? hook may return any value; only its truthiness counts.
      #: (::Sidekiq::Job, Hash[String, untyped]) -> top
      def capture_flamegraph?(job_instance, job_payload)
        return TRUTHY_STRINGS.include?(job_payload["x-singed"].to_s) if job_payload.key?("x-singed")

        # The optional capture_flamegraph? hook is duck-typed, which Sorbet can't express.
        job_class = job_class(job_instance, job_payload) #: as untyped
        return false unless job_class
        return job_class.capture_flamegraph?(job_payload) if job_class.respond_to?(:capture_flamegraph?)

        TRUTHY_STRINGS.include?(ENV.fetch("SINGED_MIDDLEWARE_ALWAYS_CAPTURE", "false"))
      end

      #: (::Sidekiq::Job, Hash[String, untyped]) -> String
      def flamegraph_label(job_instance, job_payload)
        [job_class(job_instance, job_payload), job_payload["jid"]].compact.join("--")
      end

      #: (::Sidekiq::Job, Hash[String, untyped]) -> Class[top]?
      def job_class(job_instance, job_payload)
        job_class = job_payload.fetch("wrapped", job_instance) # ActiveJob
        return job_class if job_class.is_a?(Class)
        return job_class.class if job_class.is_a?(::Sidekiq::Job)
        # Sidekiq payloads carry the job class as a string, so it can only be resolved at runtime.
        # rubocop:disable Sorbet/ConstantsFromStrings
        return job_class.constantize if job_class.respond_to?(:constantize)

        Object.const_get(job_class.to_s)
        # rubocop:enable Sorbet/ConstantsFromStrings
      rescue NameError
        nil
      end
    end
  end
end
