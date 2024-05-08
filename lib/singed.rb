# frozen_string_literal: true

require "json"
require "stackprof"
require "colorize"
require "vernier"

module Singed
  extend self

  # Where should flamegraphs be saved?
  def output_directory=(directory)
    @output_directory = Pathname.new(directory)
  end

  def self.output_directory
    @output_directory
  end

  def enabled=(enabled)
    @enabled = enabled
  end

  def enabled?
    return @enabled if defined?(@enabled)

    @enabled = true
  end

  def backtrace_cleaner=(backtrace_cleaner)
    @backtrace_cleaner = backtrace_cleaner
  end

  def backtrace_cleaner
    @backtrace_cleaner
  end

  def vernier_hooks
    @vernier_hooks ||= []
  end

  def silence_line?(line)
    return backtrace_cleaner.silence_line?(line) if backtrace_cleaner

    false
  end

  def filter_line(line)
    return backtrace_cleaner.filter_line(line) if backtrace_cleaner

    line
  end

  def profiler_klass(profiler)
    case profiler
    when :stackprof, nil then Singed::Flamegraph::Stackprof
    when :vernier then Singed::Flamegraph::Vernier
    else
      raise ArgumentError, "Unknown profiler: #{profiler}"
    end
  end

  def profile(label = "flamegraph", profiler: nil, open: true, io: $stdout, **profiler_options, &)
    profiler_klass = profiler_klass(profiler)
    fg = profiler_klass.new(
      label: label,
      announce_io: io,
      **profiler_options
    )

    result = fg.record(&)
    fg.save
    fg.open if open

    result
  end

  def stackprof(label = "stackprof", open: true, announce_io: $stdout, **stackprof_options, &)
    profile(label, profiler: :stackprof, open: open, announce_io: announce_io, **stackprof_options, &)
  end

  def vernier(label = "vernier", open: true, announce_io: $stdout, **vernier_options, &)
    profile(label, profiler: :vernier, open: open, announce_io: announce_io, **vernier_options, &)
  end

  autoload :Flamegraph, "singed/flamegraph"
  autoload :Report, "singed/report"
  autoload :RackMiddleware, "singed/rack_middleware"
end

require "singed/kernel_ext"
require "singed/railtie" if defined?(Rails::Railtie)
require "singed/rspec" if defined?(RSpec) && RSpec.respond_to?(:configure)
