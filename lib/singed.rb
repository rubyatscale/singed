# frozen_string_literal: true

require 'json'
require 'stackprof'
require 'colorize'

module Singed
  extend self

  # Where should flamegraphs be saved?
  def output_directory=(directory)
    @output_directory = Pathname.new(directory)
  end

  def self.output_directory
    @output_directory || raise("output directory hasn't been set!")
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

  autoload :Flamegraph, 'singed/flamegraph'
  autoload :Report, 'singed/report'
  autoload :RackMiddleware, 'singed/rack_middleware'
end

require 'singed/kernel_ext'
require 'singed/railtie' if defined?(Rails::Railtie)
require 'singed/rspec' if defined?(RSpec)
