# typed: strict
# frozen_string_literal: true

module Singed
  # Converts a Vernier::Result to speedscope's file format, with a profile for each thread:
  # https://github.com/jlfwong/speedscope/blob/v1.24.0/src/lib/file-format-spec.ts
  class VernierReport
    # Vernier keeps sampling threads that are waiting, and categorizes those samples. Topping their
    # stacks with one of these frames keeps waiting from reading as time spent running Ruby code.
    CATEGORY_FRAMES = {
      1 => { name: "(idle)" }, # sleeping, or waiting on I/O or a lock
      2 => { name: "(waiting for GVL)" }, # ready to run, but another thread holds the GVL
    }.freeze #: Hash[Integer, Hash[Symbol, String]]

    # Not Vernier::Result: apps' Tapioca evaluates these sigs even when Vernier isn't loaded.
    #: (untyped) -> void
    def initialize(result)
      @result = result
      @frames = [] #: Array[Hash[Symbol, untyped]]
      @func_frame_indexes = {} #: Hash[Integer, Integer]
      @category_frame_indexes = {} #: Hash[Integer, Integer]
      @stacks = {} #: Hash[[Integer, Integer], Array[Integer]]
    end

    #: (IO | StringIO) -> void
    def print_json(io)
      io.write(JSON.generate(to_h))
    end

    #: () -> Hash[Symbol, untyped]
    def to_h
      interval = @result.meta.fetch(:interval)
      # Threads that never ran while profiling have no samples, so would only add empty profiles.
      threads = @result.threads.values.select { |thread| thread[:is_start] || thread[:samples].any? }
      profiles = threads.map { |thread| profile(thread, interval) }

      {
        "$schema": "https://www.speedscope.app/file-format-schema.json",
        shared: { frames: @frames },
        profiles:,
        # The thread that started profiling is the one that ran the profiled code.
        activeProfileIndex: threads.index { |thread| thread[:is_start] },
      }
    end

    private

    #: (Hash[Symbol, untyped], Integer) -> Hash[Symbol, untyped]
    def profile(thread, interval)
      samples = thread[:samples].zip(thread[:sample_categories]).map do |stack_idx, category|
        stack(stack_idx, category)
      end
      # Vernier merges consecutive samples of the same stack into one, counting them in its weight.
      weights = thread[:weights].map { |weight| weight * interval }

      {
        type: "sampled",
        name: utf8(thread[:name]),
        unit: "microseconds",
        startValue: 0,
        endValue: weights.sum,
        samples:,
        weights:,
      }
    end

    # Vernier links each stack to its parent, but speedscope lists a stack's frames from the root.
    #: (Integer, Integer) -> Array[Integer]
    def stack(stack_idx, category)
      @stacks[[stack_idx, category]] ||= begin
        frames = [] #: Array[Integer]
        idx = stack_idx #: Integer?
        while idx
          frames << func_frame_index(stack_table.frame_func_idx(stack_table.stack_frame_idx(idx)))
          idx = stack_table.stack_parent_idx(idx)
        end
        frames.reverse!
        frames << category_frame_index(category) if CATEGORY_FRAMES.key?(category)
        frames
      end
    end

    # One frame per method rather than per line, so each method is a single box in the flamegraph.
    #: (Integer) -> Integer
    def func_frame_index(func_idx)
      @func_frame_indexes[func_idx] ||= begin
        frame = {
          name: utf8(stack_table.func_name(func_idx)),
          file: Singed.filter_line(utf8(stack_table.func_filename(func_idx))),
        } #: Hash[Symbol, untyped]
        line = stack_table.func_first_lineno(func_idx)
        frame[:line] = line if line.positive? # C functions have no line
        add_frame(frame)
      end
    end

    #: (Integer) -> Integer
    def category_frame_index(category)
      @category_frame_indexes[category] ||= add_frame(CATEGORY_FRAMES.fetch(category))
    end

    #: (Hash[Symbol, untyped]) -> Integer
    def add_frame(frame)
      @frames << frame
      @frames.size - 1
    end

    # JSON needs valid UTF-8. Vernier guesses its stack table's strings are UTF-8, so they may need scrubbing:
    # https://github.com/jhawthorn/vernier/blob/v1.11.0/ext/vernier/stack_table.cc#L179-L191
    # It names threads that have no name after Thread#inspect, which is binary.
    #: (String) -> String
    def utf8(string)
      string = string.dup.force_encoding(Encoding::UTF_8) if string.encoding == Encoding::BINARY
      string.scrub
    end

    #: () -> untyped
    def stack_table
      @result.stack_table
    end
  end
end
