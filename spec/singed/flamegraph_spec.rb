# typed: false
# frozen_string_literal: true

RSpec.describe Singed::Flamegraph do
  around do |example|
    example.run
  ensure
    Singed.instance_variable_set(:@profiler, nil)
  end

  def spin(seconds)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
    nil while Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
  end

  def load_error(message, path:)
    LoadError.new(message).tap { |error| allow(error).to receive(:path).and_return(path) }
  end

  describe "#profiler" do
    it "is Singed.profiler by default" do
      Singed.profiler = :vernier

      expect(described_class.new.profiler).to eq(:vernier)
    end

    it "is the profiler it's given" do
      Singed.profiler = :vernier

      expect(described_class.new(profiler: :stackprof).profiler).to eq(:stackprof)
    end

    it "rejects profilers Singed doesn't support" do
      expect { described_class.new(profiler: :rbspy) }.to raise_error(ArgumentError, "Unsupported profiler :rbspy, expected one of [:stackprof, :vernier]")
    end

    it "isn't supported when given an existing file" do
      expect { described_class.new(filename: Pathname("profile.json"), profiler: :vernier) }.to raise_error(ArgumentError, "profiler not supported when given an existing file")
    end

    it "explains that vernier needs installing when it can't be loaded" do
      allow(described_class).to receive(:require).with("vernier").and_raise(load_error("cannot load such file -- vernier", path: "vernier"))

      expect { described_class.new(profiler: :vernier) }.to raise_error(LoadError, "Profiling with vernier needs the vernier gem in your bundle (cannot load such file -- vernier)")
    end

    it "doesn't blame the bundle when vernier is installed but fails to load" do
      error = load_error("incompatible library version - vernier.bundle", path: "/gems/vernier-1.11.0/lib/vernier/vernier.bundle")
      allow(described_class).to receive(:require).with("vernier").and_raise(error)

      expect { described_class.new(profiler: :vernier) }.to raise_error(error)
    end

    it "needs vernier 1.5 or newer" do
      stub_const("Vernier::VERSION", "1.4.0")

      expect { described_class.new(profiler: :vernier) }.to raise_error(LoadError, "Profiling with vernier needs vernier 1.5 or newer, not 1.4.0")
    end
  end

  context "with vernier" do
    subject(:flamegraph) { described_class.new(label: "vernier", profiler: :vernier) }

    it "records a Vernier::Result" do
      flamegraph.record { spin(0.01) }

      expect(flamegraph.profile).to be_a(Vernier::Result)
    end

    it "saves a speedscope profile for each thread" do
      flamegraph.record do
        Thread.new do
          Thread.current.name = "singed-spec"
          spin(0.05)
        end.join
      end
      flamegraph.save

      json = JSON.parse(flamegraph.filename.read)
      expect(json).to include("$schema" => "https://www.speedscope.app/file-format-schema.json")
      expect(json["profiles"].map { |profile| profile["name"] }).to include("singed-spec")
      # It opens on the thread that recorded, which waited in Thread#join while the other one ran.
      active_frames = json["profiles"][json["activeProfileIndex"]]["samples"].flatten.map { |idx| json["shared"]["frames"][idx]["name"] }
      expect(active_frames).to include("Thread#join")
    end
  end
end
