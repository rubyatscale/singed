# typed: false
# frozen_string_literal: true

describe Kernel do
  let(:flamegraph) do
    instance_double(Singed::Flamegraph)
  end
  let(:io) { StringIO.new }

  before do
    allow(Singed::Flamegraph).to receive(:new).and_return(flamegraph)
    allow(flamegraph).to receive(:record)
    allow(flamegraph).to receive(:save)
    allow(flamegraph).to receive(:open)
    allow(flamegraph).to receive(:open_command)
    allow(flamegraph).to receive(:filename)
  end

  it "works without any arguments" do
    # * except what's needed to test
    # NOTE: use Object.new to get the actual flamegraph kernel extension, instead of the rspec-specific flamegraph
    Object.new.flamegraph(io:) do
    end

    expect(Singed::Flamegraph).to have_received(:new).with(label: nil, ignore_gc: false, interval: 1000, profiler: nil)
  end

  it "works with explicit arguments" do
    # NOTE: use Object.new to get the actual flamegraph kernel extension, instead of the rspec-specific flamegraph
    Object.new.flamegraph("yellowjackets", ignore_gc: true, interval: 2000, profiler: :vernier, io:) do
    end

    expect(Singed::Flamegraph).to have_received(:new).with(label: "yellowjackets", ignore_gc: true, interval: 2000, profiler: :vernier)
  end

  context "with default options" do
    it "opens" do
      Object.new.flamegraph(io:) do
      end

      expect(flamegraph).to have_received(:open)
    end
  end

  context "with open: true" do
    it "opens" do
      Object.new.flamegraph(open: true, io:) do
      end

      expect(flamegraph).to have_received(:open)
    end
  end

  context "with open: false" do
    it "doesn't open" do
      Object.new.flamegraph(open: false, io:) do
      end

      expect(flamegraph).to_not have_received(:open)
    end
  end
end
