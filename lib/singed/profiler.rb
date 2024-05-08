module Singed
  class Profiler
    attr_accessor :filename

    def initialize(filename:)
      @filename = filename
    end

    def record
      raise UnimplementedError
    end

    def save
      raise UnimplementedError
    end

    def open
      system open_command
    end

    def open_command
      raise UnimplementedError
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
  end
end
