# Singed

Singed makes it easy to get a flamegraph anywhere in your code base. It wraps profiling your code with [stackprof](https://github.com/tmm1/stackprof) or [rbspy](https://github.com/rbspy/rbspy), and then launching [speedscope](https://github.com/jlfwong/speedscope) to view it.

## Installation

Add to `Gemfile`:

```ruby
gem "singed"
```

Then run `bundle install`

Then run `npm install -g speedscope`

## Usage

The simplest way is to wrap your code with a block

```ruby
flamegraph {
  # your code here
}
```

Flamegraphs are saved for later review to `Singed.output_directory`, which is `tmp/speedscope` on Rails. You can adjust this like:

```ruby
Singed.output_directory = "tmp/slowness-exploration"
```

#### Block form
If you are calling it in a loop, or with different variations, you can include a label on the filename:

```ruby
flamegraph("rspec") {
  # your code here
}
```

You can also skip opening speedscope in a browser automatically:

```ruby
flamegraph(open: false) {
  # your code here
}
```

#### RSpec

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

#### Controllers

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

#### Rack/Rails requests

To capture the whole request, there is a middleware which checks for the  `X-Singed` header to be 'true'. With curl, you can do this like:

```shell
curl -H 'X-Singed: true' https://localhost:3000
```

PROTIP: use Chrome Developer Tools to record network activity, and copy requests as a curl command. Add `-H 'X-Singed: true'` to it, and you get flamegraphs!

This can also be enabled to always run by setting `SINGED_MIDDLEWARE_ALWAYS_CAPTURE=1`  in the environment.

#### Command Line

There is a `singed` command line you can use that will record a flamegraph from the entirety of a command run:

```shell
$ bundle binstub singed # if you want to be able to call it like bin/singed
$ bundle exec singed -- bin/rails runner 'Model.all.to_a'
```

The flamegraph is opened afterwards.

## How to read a flamegraph

You've generated a flamegraph, now what? That's a great question. Here's some resources for getting started:

- [technicalpickles/flamegraph-lighting-talk](https://github.com/technicalpickles/flamegraph-lighting-talk)
- [Pairin' with Aaron: Flamegraphs and App Performance - YouTube](https://www.youtube.com/watch?v=9nvX3OHykGQ)

## Limitations

When using the auto-opening feature, it's assumed that you are have a browser available on the same host you are profiling code.

The `open` is expected to be available.

## Alternatives

- using [rbspy](https://rbspy.github.io/) directly
- using [stackprof](https://github.com/tmm1/stackprof) (a dependency of singed) directly
