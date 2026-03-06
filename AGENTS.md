This file provides guidance to AI coding agents when working with code in this repository.

## What this project is

`singed` makes it easy to get a flamegraph anywhere in a Ruby codebase. It wraps profiling with [stackprof](https://github.com/tmm1/stackprof) or [rbspy](https://github.com/rbspy/rbspy) and launches [speedscope](https://github.com/jlfwong/speedscope) to view results.

## Commands

```bash
bundle install

# Run all tests (RSpec)
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/path/to/spec.rb

# Lint
bundle exec rubocop
bundle exec rubocop -a  # auto-correct
```

## Architecture

- `lib/singed.rb` — main entry point; provides `Singed.flamegraph` block helper
- `lib/singed/` — core classes: flamegraph output handling, stackprof/rbspy integrations, speedscope launcher
- `spec/` — RSpec tests
