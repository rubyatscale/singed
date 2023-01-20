# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'singed'

  spec.version       = '0.1.0'
  spec.authors       = ['Josh Nichols']
  spec.email         = ['josh.nichols@gusto.com']

  spec.summary       = 'Quick and easy way to get flamegraphs from a specific part of your code base'
  spec.required_ruby_version = '>= 2.7.0'

  # spec.metadata['allowed_push_host'] = "TODO: Set to your gem server 'https://example.com'"

  spec.files         = Dir['README.md', '*.gemspec', 'lib/**/*', 'exe/**/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r(\Aexe/)) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'colorize'
  spec.add_dependency 'stackprof'

  spec.add_development_dependency 'rake', '~> 13.0'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
