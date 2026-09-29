# typed: strict
# frozen_string_literal: true

require "json"
require "stackprof"

module Singed
  # Methods defined with plain `def` below are both module methods (Singed.start) and public
  # instance methods of Singed, which is how the gem has shipped since its first release.
  # `class << self` would remove those instance methods for anyone who includes or extends Singed.
  extend self # rubocop:disable Style/ModuleFunction

  # Where should flamegraphs be saved?
  #: (String | Pathname | nil) -> void
  def output_directory=(directory)
    @output_directory = directory && Pathname.new(directory) #: Pathname?
  end

  #: () -> Pathname?
  def self.output_directory
    @output_directory
  end

  #: (bool?) -> void
  def enabled=(enabled)
    @enabled = enabled #: bool?
  end

  #: () -> bool?
  def enabled?
    return @enabled if defined?(@enabled)

    @enabled = true
  end

  # Not ActiveSupport::BacktraceCleaner: apps' Tapioca evaluates these sigs even when ActiveSupport isn't loaded.
  #: (untyped) -> void
  def backtrace_cleaner=(backtrace_cleaner)
    @backtrace_cleaner = backtrace_cleaner #: untyped
  end

  #: () -> untyped
  def backtrace_cleaner
    @backtrace_cleaner
  end

  #: (String) -> bool
  def silence_line?(line)
    cleaner = backtrace_cleaner
    return cleaner.silence_line?(line) if cleaner

    false
  end

  #: (String) -> String
  def filter_line(line)
    cleaner = backtrace_cleaner
    return cleaner.filter_line(line) if cleaner

    line
  end

  #: (?String?, ?ignore_gc: bool, ?interval: Integer) -> Flamegraph?
  def start(label = nil, ignore_gc: false, interval: 1000)
    return unless enabled?
    return if profiling?

    @current_flamegraph = Flamegraph.new(label:, ignore_gc:, interval:)
    @current_flamegraph.tap(&:start)
  end

  #: () -> Flamegraph?
  def stop
    return nil unless profiling?

    # profiling? is only true while @current_flamegraph is set.
    flamegraph = @current_flamegraph #: as !nil
    @current_flamegraph = nil #: Flamegraph?
    flamegraph.stop
    flamegraph.save
    flamegraph
  end

  #: () -> bool
  def profiling?
    @current_flamegraph&.started? || false
  end

  autoload :Flamegraph, "singed/flamegraph"
  autoload :Report, "singed/report"
  autoload :RackMiddleware, "singed/rack_middleware"
  autoload :Speedscope, "singed/speedscope"
end

require "singed/kernel_ext"
require "singed/railtie" if defined?(Rails::Railtie)
require "singed/rspec" if defined?(RSpec) && RSpec.respond_to?(:configure)
