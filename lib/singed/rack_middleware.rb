# Rack Middleware

require "rack"

module Singed
  class RackMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if capture_flamegraph?(env)
        flamegraph { @app.call(env) }
      else
        @app.call(env)
      end
    end

    def capture_flamegraph?(env)
      self.class.always_capture? || env["HTTP_X_SINGED"] == "true"
    end

    TRUTHY_STRINGS = ["true", "1", "yes"].freeze

    def self.always_capture?
      return @always_capture if defined?(@always_capture)

      @always_capture = TRUTHY_STRINGS.include?(ENV.fetch("SINGED_MIDDLEWARE_ALWAYS_CAPTURE", "false"))
    end
  end
end
