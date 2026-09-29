# typed: strict
# frozen_string_literal: true

module ActiveSupport
  class BacktraceCleaner
    #: (String) -> String
    def filter_line(line)
      filtered_line = line
      @filters.each do |f|
        filtered_line = f.call(filtered_line)
      end

      filtered_line
    end

    #: (String) -> bool
    def silence_line?(line)
      @silencers.any? { |s| s.call(line) }
    end
  end
end
