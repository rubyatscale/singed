module Kernel
  def flamegraph(label = nil, open: true, io: $stdout, **stackprof_kwargs, &)
    fg = Singed::Flamegraph::Stackprof.new(
      label: label,
      announce_io: io,
      **stackprof_kwargs
    )
    result = fg.record(&)
    fg.save
    fg.open if open

    result
  end
end
