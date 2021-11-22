# Rack Middleware

require 'rack'

module Singed
  class RackMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = if capture_flamegraph?(env)
        flamegraph do
          @app.call(env)
        end
      else
        @app.call(env)
      end

      [status, headers, body]
    end

    def capture_flamegraph?(env)
      env['HTTP_X_SINGED'] == 'true'
    end
  end
end
