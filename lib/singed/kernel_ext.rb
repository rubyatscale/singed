module Kernel
  def flamegraph(label = nil, open: true, ignore_gc: false, interval: 1000, io: $stdout, &)
    fg = Singed::Flamegraph.new(label: label, ignore_gc: ignore_gc, interval: interval)
    result = fg.record(&)
    fg.save

    # avoid a dep on a colorizing gem by doing this ourselves
    bright_red = "\e[91m"
    none = "\e[0m"
    if open
      # use npx, so we don't have to add it as a dependency
      io.puts "🔥📈 #{bright_red}Captured flamegraph, opening with#{none}: #{fg.open_command}"
      fg.open
    else
      io.puts "🔥📈 #{bright_red}Captured flamegraph to file#{none}: #{fg.filename}"
    end

    result
  end
end
