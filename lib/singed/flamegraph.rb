module Singed
  class Flamegraph
    attr_accessor :profile, :filename

    def initialize(label: nil, ignore_gc: false, interval: 1000, filename: nil)
      # it's been created elsewhere, ie rbspy
      if filename
        if ignore_gc
          raise ArgumentError, "ignore_gc not supported when given an existing file"
        end

        if label
          raise ArgumentError, "label not supported when given an existing file"
        end

        @filename = filename
      else
        @ignore_gc = ignore_gc
        @interval = interval
        @time = Time.now # rubocop:disable Rails/TimeZone
        @filename = self.class.generate_filename(label: label, time: @time)
      end

      @profiler = Singed::Profiler::VernierProfiler.new(filename: @filename)
      # @profiler = Singed::Profiler::StackprofPlusSpeedscopeProfiler.new(filename: @filename)
    end

    def record(&block)
      return yield unless Singed.enabled?
      return yield if filename.exist? # file existing means its been captured already

      @profiler.record(&block)
    end

    def save
      @profiler.save
    end

    def open
      @profiler.open
    end

    def open_command
      @profiler.open_command
    end

    def self.generate_filename(label: nil, time: Time.now) # rubocop:disable Rails/TimeZone
      formatted_time = time.strftime("%Y%m%d%H%M%S-%6N")
      basename_parts = ["speedscope", label, formatted_time].compact

      file = Singed.output_directory.join("#{basename_parts.join("-")}.json")
      # convert to relative directory if it's an absolute path and within the current
      pwd = Pathname.pwd
      file = file.relative_path_from(pwd) if file.absolute? && file.to_s.start_with?(pwd.to_s)
      file
    end
  end
end
