module Kernel
  def flamegraph(label = nil, open: true, &block)
    fg = Singed::Flamegraph.new(label: label)
    result = fg.record(&block)
    fg.save

    if open
      # use npx, so we don't have to add it as a dependency
      puts "🔥📈 #{'Captured flamegraph, opening with'.colorize(:bold).colorize(:red)}: #{fg.open_command}"
      fg.open
    else
      puts "🔥📈 #{'Captured flamegraph to file'.colorize(:bold).colorize(:red)}: #{fg.filename}"
    end

    result
  end
end
