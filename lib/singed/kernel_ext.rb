module Kernel
  def flamegraph(label = nil, open: true, ignore_gc: false, interval: 1000, io: $stdout, &)
    fg = Singed::Flamegraph::Stackprof.new(label: label, ignore_gc: ignore_gc, interval: interval)
    result = fg.record(&)
    fg.save
    fg.open if open

    result
  end
end
