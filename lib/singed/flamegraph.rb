module Singed
  class Flamegraph
    attr_accessor :profile, :filename, :announce_io

    def initialize(label: nil, announce_io: $stdout)
      @time = Time.now
      @announce_io = announce_io
      @filename ||= self.class.generate_filename(label: label, time: @time)
    end

    def record(&block)
      raise NotImplementedError
    end

    def record?
      Singed.enabled?
    end

    def save
      raise NotImplementedError
    end

    def open_command
      raise NotImplementedError
    end

    def open(open: true)
      if open
        # use npx, so we don't have to add it as a dependency
        announce_io.puts "🔥📈 #{"Captured flamegraph, opening with".colorize(:bold).colorize(:red)}: #{open_command}"
        system open_command
      else
        announce_io.puts "🔥📈 #{"Captured flamegraph to file".colorize(:bold).colorize(:red)}: #{filename}"
      end
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

    class Stackprof < Flamegraph
      def initialize(label: nil, ignore_gc: false, interval: 1000)
        super(label: label)
      end

      def record(&block)
        result = nil
        @profile = ::StackProf.run(mode: :wall, raw: true, ignore_gc: @ignore_gc, interval: @interval) do
          result = yield
        end
        result
      end

      def save
        if filename.exist?
          raise ArgumentError, "File #{filename} already exists"
        end

        report = Singed::Report.new(@profile)
        report.filter!
        filename.dirname.mkpath
        filename.open("w") { |f| report.print_json(f) }
      end

      def open_command
        # use npx, so we don't have to add it as a dependency
        @open_command ||= "npx speedscope #{@filename}"
      end
    end

    class Vernier < Flamegraph
      def initialize(label: nil, interval: 1000, hooks: nil, gc: true)
        super(label: label)
        @interval = interval
        @hooks = hooks || Singed.vernier_hooks
        @gc = gc
      end

      def record
        ::Vernier.run(out: filename.to_s, interval: @interval, hooks: @hooks, gc: @gc) do
          yield
        end
      end

      def open_command
        @open_command ||= "profile-viewer #{@filename}"
      end

      def save
        # no-op, since it already writes out
      end
    end
  end
end
