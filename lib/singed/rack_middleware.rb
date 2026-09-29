# typed: strict
# frozen_string_literal: true

# Rack Middleware

require "rack"

module Singed
  class RackMiddleware
    # Rack apps are duck-typed: any object that responds to call(env).
    #: (untyped) -> void
    def initialize(app)
      @app = app
    end

    # Returns the wrapped app's Rack response unchanged, so it is as untyped as the app.
    #: (Hash[String, untyped]) -> untyped
    def call(env)
      if capture_flamegraph?(env)
        flamegraph { @app.call(env) }
      else
        @app.call(env)
      end
    end

    #: (Hash[String, untyped]) -> bool
    def capture_flamegraph?(env)
      self.class.always_capture? || env["HTTP_X_SINGED"] == "true"
    end

    TRUTHY_STRINGS = ["true", "1", "yes"].freeze

    # bool?, not bool: Sorbet can't tell that defined?(@always_capture) means it holds a bool.
    #: () -> bool?
    def self.always_capture?
      return @always_capture if defined?(@always_capture)

      @always_capture = TRUTHY_STRINGS.include?(ENV.fetch("SINGED_MIDDLEWARE_ALWAYS_CAPTURE", "false")) #: bool?
    end
  end
end
