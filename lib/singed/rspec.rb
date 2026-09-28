# typed: true
# frozen_string_literal: true

require "singed"

RSpec.configure do |config|
  config.around(flamegraph: true) do |example|
    flamegraph { example.run }
  end
end
