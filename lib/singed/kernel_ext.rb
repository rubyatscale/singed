# typed: strict
# frozen_string_literal: true

module Kernel
  #: [Result] (
  #|   ?String?,
  #|   ?open: bool,
  #|   ?ignore_gc: bool,
  #|   ?interval: Integer,
  #|   ?io: IO | StringIO
  #| ) { () -> Result } -> Result
  def flamegraph(label = nil, open: true, ignore_gc: false, interval: 1000, io: $stdout, &block)
    fg = Singed::Flamegraph.new(label:, ignore_gc:, interval:)
    result = fg.record(&block)
    fg.save

    # avoid a dep on a colorizing gem by doing this ourselves
    bright_red = "\e[91m"
    none = "\e[0m"
    if open
      io.puts "🔥📈 #{bright_red}Captured flamegraph, opening with#{none}: #{fg.open_command}"
      fg.open
    else
      io.puts "🔥📈 #{bright_red}Captured flamegraph to file#{none}: #{fg.filename}"
    end

    result
  end
end
