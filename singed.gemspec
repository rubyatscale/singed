# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "singed"

  spec.version = "0.2.2"
  spec.license = "MIT"
  spec.authors = ["Josh Nichols"]
  spec.email = ["josh.nichols@gusto.com"]

  spec.summary = "Quick and easy way to get flamegraphs from a specific part of your code base"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir["README.md", "*.gemspec", "lib/**/*", "exe/**/*"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize"
  spec.add_dependency "stackprof", ">= 0.2.13"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
