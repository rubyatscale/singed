module ActiveSupport
  class BacktraceCleaner
    def filter_line(line)
      filtered_line = line
      @filters.each do |f|
        filtered_line = f.call(filtered_line)
      end

      filtered_line
    end

    def silence_line?(line)
      @silencers.any? { |s| s.call(line) }
    end
  end
end
