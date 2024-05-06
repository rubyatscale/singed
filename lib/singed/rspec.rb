require "singed"

RSpec.configure do |config|
  config.around(flamegraph: true) do |example|
    flamegraph { example.run }
  end
end
