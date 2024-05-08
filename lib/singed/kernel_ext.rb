module Kernel
  def flamegraph(label = nil, profiler: nil, open: true, io: $stdout, **profiler_options, &)
    Singed.profile(label, profiler: profiler, open: open, io: io, **profiler_options, &)
  end
end
