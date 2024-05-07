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
    end

    def record
      return yield unless Singed.enabled?
      return yield if filename.exist? # file existing means its been captured already

      result = nil
      @profile = StackProf.run(mode: :wall, raw: true, ignore_gc: @ignore_gc, interval: @interval) do
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

    def open
      system open_command
    end

    def open_command
      @open_command ||= "npx speedscope #{@filename}"
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
