require 'singed'

if defined?(Rspec)
  RSpec.configure do |config|
    config.around do |example|
      if example.metadata[:flamegraph]
        flamegraph { example.run }
      else
        example.run
      end
    end
  end
end
