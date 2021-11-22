module Singed
  class Flamegraph
    attr_accessor :profile

    def initialize(label: nil)
      @time = Time.now # rubocop:disable Rails/TimeZone
      @filename = Singed.output_directory.join("speedscope#{'-' if label.present?}#{label}-#{@time.to_formatted_s(:number)}.json").relative_path_from(Pathname.pwd)
    end

    def record
      return yield unless Singed.enabled?

      result = nil
      @profile = StackProf.run(mode: :wall, raw: true) do
        result = yield
      end
      result
    end

    def save
      report = Singed::Report.new(@profile)
      report.filter!
      @filename.dirname.mkpath
      @filename.open('w') { |f| report.print_json(f) }
    end

    def open
      system open_command
    end

    def open_command
      @open_command ||= "npx speedscope #{@filename}"
    end
  end
end
