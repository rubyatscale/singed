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

# Type check (Sorbet)
bundle exec srb tc

# Regenerate gem RBIs after Gemfile.lock changes
bin/tapioca gems
```

## Architecture

- `lib/singed.rb` — main entry point; provides `Singed.flamegraph` block helper
- `lib/singed/` — core classes: flamegraph output handling, stackprof/rbspy integrations, speedscope launcher
- `spec/` — RSpec tests

## Types

- Files under `lib/` are `# typed: strict`. Write their signatures as [RBS comments](https://sorbet.org/docs/rbs-support) (`#: (String) -> bool`), not `sig` blocks.
- `sorbet-runtime` isn't a dependency of the gem, so nothing under `lib/` may reference `T` at runtime. Use the RBS assertion comments (`#: Type`, `#: as !nil`, `#: as Type`, `#: as untyped`, `#: self as Type`) instead of `T.let`, `T.must`, `T.cast`, `T.unsafe` and `T.bind`.
- Apps that use Tapioca still run these signatures: Tapioca rewrites RBS comments into runtime-checked `sig`s while it loads the app. A signature must therefore only name constants that are loaded whenever its file is (not `ActiveSupport` in `lib/singed.rb`), and must accept every value an app can pass while booting, such as `flamegraph [:show, :index]` in a controller. Otherwise the app's `tapioca gem` or `tapioca dsl` run errors. The specs here don't load `sorbet-runtime`, so they can't catch this.
- Types the generated gem RBIs are missing go in `sorbet/rbi/shims/`.

## Pull requests

PR titles must follow Conventional Commits (`feat: ...`, `fix: ...`, `chore: ...`, with `!` for a breaking change). release-please uses the squash-merged title to pick the next version and write the changelog entry. Don't edit `lib/singed/version.rb` or `CHANGELOG.md` by hand; the release PR does that.
