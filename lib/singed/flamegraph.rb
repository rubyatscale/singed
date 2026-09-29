# typed: strict
# frozen_string_literal: true

module Singed
  class Flamegraph
    PROFILERS = [:stackprof, :vernier].freeze
    # The first with Vernier::Result#stack_table.
    MINIMUM_VERNIER_VERSION = "1.5"

    # The StackProf.results hash, whose values vary by key, or a Vernier::Result when profiling with Vernier.
    # Not typed as Vernier::Result: apps' Tapioca evaluates this sig even when Vernier isn't loaded.
    #: untyped
    attr_accessor :profile

    #: Pathname
    attr_accessor :filename

    # nil when wrapping an existing file.
    #: Symbol?
    attr_reader :profiler

    #: (?label: String?, ?ignore_gc: bool, ?interval: Integer, ?profiler: Symbol?, ?filename: Pathname?) -> void
    def initialize(label: nil, ignore_gc: false, interval: 1000, profiler: nil, filename: nil)
      # it's been created elsewhere, ie rbspy
      if filename
        if ignore_gc
          raise ArgumentError, "ignore_gc not supported when given an existing file"
        end

        if label
          raise ArgumentError, "label not supported when given an existing file"
        end

        if profiler
          raise ArgumentError, "profiler not supported when given an existing file"
        end

        @filename = filename #: Pathname
      else
        profiler ||= Singed.profiler
        self.class.load_profiler(profiler)

        # Nilable because they stay unset when wrapping an existing file, and #start still reads them.
        @profiler = profiler #: Symbol?
        @ignore_gc = ignore_gc #: bool?
        @interval = interval #: Integer?
        @time = Time.now #: Time
        @filename = self.class.generate_filename(label:, time: @time)
      end
    end

    #: [Result] () { () -> Result } -> Result
    def record(&_block)
      start
      yield
    ensure
      stop
    end

    #: () -> bool
    def start
      return false unless Singed.enabled?
      return false if filename.exist? # file existing means its been captured already
      return false if started?

      if vernier?
        # A collector per flamegraph, rather than Vernier.start_profile, which raises if a profile is already running.
        # There's no ignore_gc to pass: Vernier doesn't sample a thread while it's running GC.
        @collector = Vernier::Collector.new(:wall, interval: @interval) #: untyped
        @collector.start
      else
        StackProf.start(mode: :wall, raw: true, ignore_gc: @ignore_gc, interval: @interval)
      end
      @started = true
    end

    #: () -> untyped
    def stop
      return nil unless started?

      @started = false #: bool?
      if vernier?
        @profile = @collector.stop
      else
        StackProf.stop
        @profile = StackProf.results
      end
    end

    #: () -> bool
    def started?
      !!@started
    end

    #: () -> void
    def save
      if filename.exist?
        raise ArgumentError, "File #{filename} already exists"
      end

      if vernier?
        report = Singed::VernierReport.new(@profile)
      else
        report = Singed::Report.new(@profile)
        report.filter!
      end
      filename.dirname.mkpath
      filename.open("w") { |f| report.print_json(f) }
    end

    #: () -> bool?
    def open
      Singed::Speedscope.open(@filename)
    end

    #: () -> String
    def open_command
      Singed::Speedscope.open_command(@filename)
    end

    #: (?label: String?, ?time: Time) -> Pathname
    def self.generate_filename(label: nil, time: Time.now)
      formatted_time = time.strftime("%Y%m%d%H%M%S-%6N")
      basename_parts = ["speedscope", label, formatted_time].compact

      # Callers must set output_directory first (the Railtie and CLI do); unset, this raises NoMethodError.
      file = Singed.output_directory #: as !nil
        .join("#{basename_parts.join('-')}.json")
      # convert to relative directory if it's an absolute path and within the current
      pwd = Pathname.pwd
      file = file.relative_path_from(pwd) if file.absolute? && file.to_s.start_with?(pwd.to_s)
      file
    end

    # Raises unless Singed supports the profiler. Requires vernier, which Singed doesn't depend on, when it's the one asked for.
    #: (Symbol) -> void
    def self.load_profiler(profiler)
      unless PROFILERS.include?(profiler)
        raise ArgumentError, "Unsupported profiler #{profiler.inspect}, expected one of #{PROFILERS.inspect}"
      end
      return unless profiler == :vernier

      begin
        require "vernier"
      rescue LoadError => e
        # Other paths mean vernier is installed but broken, e.g. its native extension didn't load.
        raise unless e.path == "vernier"

        raise LoadError, "Profiling with vernier needs the vernier gem in your bundle (#{e.message})"
      end

      if Gem::Version.new(Vernier::VERSION) < Gem::Version.new(MINIMUM_VERNIER_VERSION)
        raise LoadError, "Profiling with vernier needs vernier #{MINIMUM_VERNIER_VERSION} or newer, not #{Vernier::VERSION}"
      end
    end

    private

    #: () -> bool
    def vernier?
      @profiler == :vernier
    end
  end
end
