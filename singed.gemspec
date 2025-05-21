# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "singed"

  spec.version = "0.3.0"
  spec.license = "MIT"
  spec.authors = ["Josh Nichols"]
  spec.email = ["josh.nichols@gusto.com"]
  spec.summary = "Quick and easy way to get flamegraphs from a specific part of your code base"
  spec.required_ruby_version = ">= 2.7.0"
  spec.homepage = "https://github.com/rubyatscale/singed"
  spec.metadata = {
    "source_code_uri" => "https://github.com/rubyatscale/singed",
    "bug_tracker_uri" => "https://github.com/rubyatscale/singed/issues",
    "homepage_uri" => "https://github.com/rubyatscale/singed"
  }

  spec.files = Dir["README.md", "*.gemspec", "lib/**/*", "exe/**/*"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "stackprof", ">= 0.2.13"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec"
end
