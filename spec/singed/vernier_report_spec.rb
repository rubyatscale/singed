# typed: false
# frozen_string_literal: true

require "vernier"

RSpec.describe Singed::VernierReport do
  subject(:report) { described_class.new(result).to_h }

  let(:result) { instance_double(Vernier::Result, meta: { interval: 500 }, threads:, stack_table:) }

  # Vernier's tables, keyed by index: each stack is a frame on top of its parent stack,
  # each frame is a line in a function.
  let(:funcs) do
    [
      ["<main>", "/app/script.rb", 1],
      ["Worker#run", "/app/worker.rb", 3],
      ["Kernel#sleep", "<cfunc>", 0],
    ]
  end
  let(:frame_funcs) { [0, 1, 1, 2] } # frames 1 and 2 are different lines of Worker#run
  let(:stacks) do
    [
      [nil, 0], # <main>
      [0, 1],   # <main> > Worker#run
      [0, 2],   # <main> > Worker#run
      [2, 3],   # <main> > Worker#run > Kernel#sleep
    ]
  end
  let(:stack_table) do
    instance_double(Vernier::StackTable).tap do |stack_table|
      allow(stack_table).to receive(:stack_parent_idx) { |idx| stacks.fetch(idx)[0] }
      allow(stack_table).to receive(:stack_frame_idx) { |idx| stacks.fetch(idx)[1] }
      allow(stack_table).to receive(:frame_func_idx) { |idx| frame_funcs.fetch(idx) }
      allow(stack_table).to receive(:func_name) { |idx| funcs.fetch(idx)[0] }
      allow(stack_table).to receive(:func_filename) { |idx| funcs.fetch(idx)[1] }
      allow(stack_table).to receive(:func_first_lineno) { |idx| funcs.fetch(idx)[2] }
    end
  end
  let(:threads) do
    {
      8 => { name: "worker", is_start: false, samples: [1], weights: [4], sample_categories: [2] },
      16 => { name: "never ran", is_start: false, samples: [], weights: [], sample_categories: [] },
      24 => { name: "main", is_start: true, samples: [1, 2, 3], weights: [2, 1, 3], sample_categories: [0, 0, 1] },
    }
  end

  def frame_names(profile)
    profile[:samples].map { |stack| stack.map { |idx| report[:shared][:frames][idx][:name] } }
  end

  it "is a speedscope file" do
    expect(report).to include("$schema": "https://www.speedscope.app/file-format-schema.json")
  end

  it "has a profile for each thread that recorded samples" do
    expect(report[:profiles].map { |profile| profile[:name] }).to eq(["worker", "main"])
  end

  it "opens on the thread that started profiling" do
    expect(report[:activeProfileIndex]).to eq(1)
  end

  it "keeps the thread that started profiling, even without samples" do
    threads[24].merge!(samples: [], weights: [], sample_categories: [])

    expect(report[:profiles].map { |profile| profile[:name] }).to eq(["worker", "main"])
  end

  it "lists each sample's frames from the root" do
    expect(frame_names(report[:profiles][1])).to eq(
      [
        ["<main>", "Worker#run"],
        ["<main>", "Worker#run"],
        ["<main>", "Worker#run", "Kernel#sleep", "(idle)"],
      ]
    )
  end

  it "tops the stacks of threads waiting for the GVL" do
    expect(frame_names(report[:profiles][0])).to eq([["<main>", "Worker#run", "(waiting for GVL)"]])
  end

  it "has one frame per function" do
    expect(report[:shared][:frames]).to contain_exactly(
      { name: "<main>", file: "/app/script.rb", line: 1 },
      { name: "Worker#run", file: "/app/worker.rb", line: 3 },
      { name: "Kernel#sleep", file: "<cfunc>" },
      { name: "(idle)" },
      { name: "(waiting for GVL)" }
    )
  end

  it "shares each category's frame between stacks" do
    threads[24].merge!(samples: [1, 3], weights: [1, 1], sample_categories: [1, 1])

    expect(report[:shared][:frames].count { |frame| frame[:name] == "(idle)" }).to eq(1)
  end

  it "filters file names the way it filters backtraces" do
    allow(Singed).to receive(:filter_line) { |line| line.delete_prefix("/app/") }

    expect(report[:shared][:frames].filter_map { |frame| frame[:file] }).to contain_exactly("script.rb", "worker.rb", "<cfunc>")
  end

  it "scrubs names that aren't valid UTF-8" do
    funcs[1][0] = "Worker#r\xFFn"

    expect(report[:shared][:frames]).to include({ name: "Worker#r�n", file: "/app/worker.rb", line: 3 })
  end

  it "scrubs thread names that aren't valid UTF-8" do
    threads[8][:name] = "work\xFFer"

    expect(report[:profiles][0][:name]).to eq("work�er")
  end

  it "reads binary thread names as UTF-8" do
    # Vernier names threads that have no name after Thread#inspect, which is binary.
    threads[8][:name] = "wörker".b

    expect(report[:profiles][0][:name]).to eq("wörker")
  end

  it "weighs samples in microseconds, as Vernier's sampling interval times the samples each one merges" do
    expect(report[:profiles][1]).to include(unit: "microseconds", weights: [1000, 500, 1500], startValue: 0, endValue: 3000)
  end

  describe "#print_json" do
    it "writes the report as JSON" do
      io = StringIO.new
      described_class.new(result).print_json(io)

      expect(JSON.parse(io.string, symbolize_names: true)).to eq(report)
    end
  end
end
