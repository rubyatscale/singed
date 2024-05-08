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

  def stackprof(label = "stackprof", open: true, ignore_gc: false, interval: 1000, io: $stdout, &)
    fg = Singed::Flamegraph::Stackprof.new(label: label, ignore_gc: ignore_gc, interval: interval)
    result = fg.record(&)
    fg.save
    fg.open if open

    result
  end

  def vernier(label = "vernier", open: true, interval: 1000, hooks: nil, gc: true, io: $stdout, &)
    fg = Singed::Flamegraph::Vernier.new(label: label, interval: interval, hooks: hooks, gc: gc)
    result = fg.record(&)
    fg.save
    fg.open if open

    result
  end

  autoload :Flamegraph, "singed/flamegraph"
  autoload :Profiler, "singed/profiler"
  autoload :Report, "singed/report"
  autoload :RackMiddleware, "singed/rack_middleware"
end

require "singed/kernel_ext"
require "singed/railtie" if defined?(Rails::Railtie)
require "singed/rspec" if defined?(RSpec) && RSpec.respond_to?(:configure)
