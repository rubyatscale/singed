# typed: strict
# frozen_string_literal: true

module Singed
  class Flamegraph
    # The StackProf.results hash; its values vary by key.
    #: Hash[Symbol, untyped]?
    attr_accessor :profile

    #: Pathname
    attr_accessor :filename

    #: (?label: String?, ?ignore_gc: bool, ?interval: Integer, ?filename: Pathname?) -> void
    def initialize(label: nil, ignore_gc: false, interval: 1000, filename: nil)
      # it's been created elsewhere, ie rbspy
      if filename
        if ignore_gc
          raise ArgumentError, "ignore_gc not supported when given an existing file"
        end

        if label
          raise ArgumentError, "label not supported when given an existing file"
        end

        @filename = filename #: Pathname
      else
        # Nilable because they stay unset when wrapping an existing file, and #start still reads them.
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

      StackProf.start(mode: :wall, raw: true, ignore_gc: @ignore_gc, interval: @interval)
      @started = true
    end

    #: () -> Hash[Symbol, untyped]?
    def stop
      return nil unless started?

      @started = false #: bool?
      StackProf.stop
      @profile = StackProf.results
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

      report = Singed::Report.new(@profile)
      report.filter!
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
  end
end
