require "singed/sidekiq"
require "tempfile"

RSpec.configure do |config|
  config.before(:suite) do
    Sidekiq.testing!(:inline)

    Sidekiq::Client.prepend(SidekiqTestingInlineWithMiddlewares)

    Sidekiq.configure_client do |config|
      config.server_middleware do |chain|
        chain.add Singed::Sidekiq::ServerMiddleware
      end
    end

    ActiveJob::Base.queue_adapter = :sidekiq
    ActiveJob::Base.logger = Logger.new(nil)

    Singed.output_directory = Dir.mktmpdir("singed-sidekiq-spec")
  end
end

# Sidekiq doesn't invoke middlewares in inline testingmode, so we need to invoke it oursleves
module SidekiqTestingInlineWithMiddlewares
  # rubocop:disable Metrics/AbcSize
  def push(job)
    return super unless Sidekiq::Testing.inline?

    job = Sidekiq.load_json(Sidekiq.dump_json(job))
    job["jid"] ||= SecureRandom.hex(12)
    job_class = Object.const_get(job["class"])
    job_instance = job_class.new
    queue = (job_instance.sidekiq_options_hash || {}).fetch("queue", "default")
    server = Sidekiq.respond_to?(:default_configuration) ? Sidekiq.default_configuration : Sidekiq
    server.server_middleware.invoke(job_instance, job, queue) do
      job_instance.perform(*job["args"])
    end
    job["jid"]
  end
  # rubocop:enable Metrics/AbcSize
end

class SidekiqPlainJob
  include Sidekiq::Job

  def perform(*_args)
    "My job is simple"
  end
end

class SidekiqFlamegraphJob
  include Sidekiq::Job

  def self.capture_flamegraph?(payload)
    !!payload["x-flamegraph"]
  end

  def perform(*_args)
    "Phew, I'm done!"
  end
end

class ActiveJobPlainJob < ActiveJob::Base
  self.queue_adapter = :sidekiq

  def perform(*_args)
    "My job is simple"
  end
end

class ActiveJobFlamegraphJob < ActiveJob::Base
  self.queue_adapter = :sidekiq

  def self.capture_flamegraph?(_payload)
    true
  end

  def perform(*_args)
    "Phew, I'm done!"
  end
end

class ActiveJobNoFlamegraphJob < ActiveJob::Base
  self.queue_adapter = :sidekiq

  def self.capture_flamegraph?(_payload)
    false
  end

  def perform(*_args)
    "Phew, I'm done!"
  end
end
