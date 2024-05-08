module Singed
  class Profiler
    attr_accessor :filename

    def initialize(filename:)
      @filename = filename
    end

    def record
      raise NotImplementedError
    end

    def save
      raise NotImplementedError
    end

    def open
      system open_command
    end

    def open_command
      raise NotImplementedError
    end

    class StackprofPlusSpeedscopeProfiler < Profiler
      def record
        result = nil
        @profile = StackProf.run(mode: :wall, raw: true, ignore_gc: @ignore_gc, interval: @interval) do
          result = yield
        end
        result
      end

      def open_command
        @open_command ||= "npx speedscope #{@filename}"
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
    end

    class VernierProfiler < Profiler
      def record
        Vernier.run(out: filename.to_s) do
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
