# Singed

Singed makes it easy to get a flamegraph anywhere in your code base. It wraps profiling your code with [stackprof](https://github.com/tmm1/stackprof), [vernier](https://github.com/jhawthorn/vernier) or [rbspy](https://github.com/rbspy/rbspy), and then launching [speedscope](https://github.com/jlfwong/speedscope) to view it.

## Installation

Add to `Gemfile`:

```ruby
gem "singed"
```

Then run `bundle install`

Then run `npm install -g speedscope`

## Usage

Simplest is calling with a block:

```ruby
flamegraph {
  # your code here
}
```

Flamegraphs are saved for later review to `Singed.output_directory`, which is `tmp/speedscope` on Rails. You can adjust this like:

```ruby
Singed.output_directory = "tmp/slowness-exploration"
```

### Blockage
If you are calling it in a loop, or with different variations, you can include a label on the filename:

```ruby
flamegraph("rspec") {
  # your code here
}
```

You can also skip opening speedscope automatically:

```ruby
flamegraph(open: false) {
  # your code here
}
```

### Explicit start and stop

You can also start and stop the flamegraph explicitly:

```ruby
# config/boot.rb
require "singed"
Singed.output_directory ||= Dir.pwd + "/tmp/speedscope"
Singed.start
# Let some code to run here...
# and then stop the flamegraph with e.g. rails runner 'Singed.stop'
flamegraph = Singed.stop
# The flamegraph is saved to the output directory
# Open it with your browser:
flamegraph.open
```

Note that `Singed.start` can't be run multiple times in parallel, instantiate multiple `Singed::Flamegraph` objects instead and call `start` on them.

### Vernier

Singed profiles with stackprof by default. [Vernier](https://github.com/jhawthorn/vernier) profiles each thread separately instead, so a flamegraph from a multi-threaded app like Puma or Sidekiq isn't a mix of what all its threads were doing. Singed doesn't depend on vernier, so add it (1.5 or newer) to your Gemfile:

```ruby
gem "vernier"
```

Then ask for it when capturing a flamegraph. `Singed.start` and controllers' `flamegraph` take `profiler:` too:

```ruby
flamegraph(profiler: :vernier) {
  # your code here
}
```

Or make it the default, which the RSpec, controller, Rack and Sidekiq integrations below then use as well:

```ruby
Singed.profiler = :vernier
```

That loads vernier straight away, so a missing or outdated gem fails at boot. If vernier is only in some of your Gemfile's groups, set this only in the environments that load them, e.g. in `config/environments/development.rb`.

speedscope then gets a profile per thread, and opens on the thread that ran your code. Pick another thread from its title bar, or step through them with `n` and `p`. Vernier keeps sampling threads that are waiting, so their stacks end in `(idle)` while sleeping or waiting on I/O or a lock, and in `(waiting for GVL)` while another thread holds the GVL.

Vernier doesn't sample a thread while it's running garbage collection, so `ignore_gc` makes no difference with it. The `singed` command line always uses rbspy.

The flamegraph's `profile` is Vernier's own result, which you can also save for [vernier.prof](https://vernier.prof) to show GVL and GC activity alongside the flamegraph:

```ruby
Singed.stop.profile.write(out: "tmp/profile.vernier.json.gz")
```

### RSpec

If you are using RSpec, you can use the `flamegraph` metadata to capture it for you.

```ruby
# make sure this is required at somepoint, like in a spec/support file!
require 'singed/rspec' 

RSpec.describe YourClass do
  it "is slow :(", flamegraph: true do
    # your code here
  end
end
```

### Controllers

If you want to capture a flamegraph of a controller action, you can call it like:

```ruby
class EmployeesController < ApplicationController
  flamegraph :show

  def show
    # your code here
  end
end
```

This won't catch the entire request though, just once it's been routed to controller and a response has been served (ie no middleware).

If Sorbet checks the controller (`# typed: true` or stricter), also include `Singed::ControllerExt` in it. The Railtie already includes it into `ActionController::Base` at runtime, but Sorbet can't see that, so it would check `flamegraph :show` against the block form of `flamegraph` instead:

```ruby
class EmployeesController < ApplicationController
  include Singed::ControllerExt

  flamegraph :show
end
```

### Rack/Rails requests

To capture the whole request, there is a middleware which checks for the  `X-Singed` header to be 'true'. With curl, you can do this like:

```shell
curl -H 'X-Singed: true' https://localhost:3000
```

PROTIP: use Chrome Developer Tools to record network activity, and copy requests as a curl command. Add `-H 'X-Singed: true'` to it, and you get flamegraphs!

This can also be enabled to always run by setting `SINGED_MIDDLEWARE_ALWAYS_CAPTURE=1`  in the environment.

### Sidekiq

If you are using Sidekiq, you can use the `Singed::Sidekiq::ServerMiddleware` to capture flamegraphs for you.

```ruby
require "singed/sidekiq"

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Singed::Sidekiq::ServerMiddleware
  end
end
```

To capture flamegraphs for all jobs, you can set the `SINGED_MIDDLEWARE_ALWAYS_CAPTURE` environment variable to `true` the same way as the Rack middleware.

To capture flamegraphs for a specific job, you can set the `x-singed` key in the job payload to `true`.

```ruby
MyJob.set("x-singed" => true).perform_async
```

Or define a `capture_flamegraph?` method on the job class:

```ruby
class MyJob
  def self.capture_flamegraph?(payload)
    payload["flamegraph"]
  end
end
```

### Command Line

There is a `singed` command line you can use that will record a flamegraph from the entirety of a command run:

```shell
$ bundle binstub singed # if you want to be able to call it like bin/singed
$ bundle exec singed -- bin/rails runner 'Model.all.to_a'
```

The flamegraph is opened afterwards.

To profile a command that runs until it's stopped, like a server, stop it with Ctrl-C. Or, when `singed` runs in the background, such as from a script, stop it with `kill`'s default SIGTERM. Either way, rbspy stops the command and writes the flamegraph, which `singed` then opens.


## Limitations

When using the auto-opening feature, it's assumed that you are have a browser available on the same host you are profiling code.

The `open` command is expected to be available.

## Alternatives

- using [rbspy](https://rbspy.github.io/) directly
- using [stackprof](https://github.com/tmm1/stackprof) (a dependency of singed) directly
- using [vernier](https://github.com/jhawthorn/vernier) directly
