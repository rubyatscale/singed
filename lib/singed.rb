# frozen_string_literal: true

require "json"
require "stackprof"
require "pathname"

module Singed
  extend self

  attr_reader :current_flamegraph

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

  def silence_line?(line)
    return backtrace_cleaner.silence_line?(line) if backtrace_cleaner

    false
  end

  def filter_line(line)
    return backtrace_cleaner.filter_line(line) if backtrace_cleaner

    line
  end

  def start(label = nil, ignore_gc: false, interval: 1000)
    return unless enabled?
    return if profiling?

    @current_flamegraph = Flamegraph.new(label: label, ignore_gc: ignore_gc, interval: interval)
    @current_flamegraph.start
  end

  def stop
    return nil unless profiling?

    flamegraph = @current_flamegraph
    @current_flamegraph = nil
    flamegraph.stop
    flamegraph.save
    flamegraph
  end

  def profiling?
    @current_flamegraph&.started? || false
  end

  autoload :Flamegraph, "singed/flamegraph"
  autoload :Report, "singed/report"
  autoload :RackMiddleware, "singed/rack_middleware"
end

require "singed/kernel_ext"
require "singed/railtie" if defined?(Rails::Railtie)
require "singed/rspec" if defined?(RSpec) && RSpec.respond_to?(:configure)
