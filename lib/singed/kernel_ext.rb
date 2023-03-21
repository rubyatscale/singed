module Kernel
  def flamegraph(label = nil, open: true, ignore_gc: false, interval: 1000, io: $stdout, &block)
    fg = Singed::Flamegraph.new(label: label, ignore_gc: ignore_gc, interval: interval)
    result = fg.record(&block)
    fg.save

    if open
      # use npx, so we don't have to add it as a dependency
      io.puts "🔥📈 #{'Captured flamegraph, opening with'.colorize(:bold).colorize(:red)}: #{fg.open_command}"
      fg.open
    else
      io.puts "🔥📈 #{'Captured flamegraph to file'.colorize(:bold).colorize(:red)}: #{fg.filename}"
    end

    result
  end
end
