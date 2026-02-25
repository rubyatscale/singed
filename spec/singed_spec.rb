# frozen_string_literal: true

require "tempfile"
require "pathname"

RSpec.describe Singed do
  around do |example|
    original_output_directory = Singed.output_directory
    original_enabled = Singed.enabled?
    begin
      example.run
    ensure
      Singed.output_directory = original_output_directory if original_output_directory
      Singed.enabled = original_enabled
      Singed.instance_variable_set(:@current_flamegraph, nil)
    end
  end

  describe ".start" do
    before do
      Singed.enabled = true
      Singed.output_directory = Dir.mktmpdir("singed-spec")
    end

    it "creates a current flamegraph and starts profiling" do
      Singed.start

      expect(Singed.current_flamegraph).to be_a(Singed::Flamegraph)
      expect(Singed.profiling?).to be true
      expect(Singed.current_flamegraph.started?).to be true
    end

    it "does nothing when already profiling" do
      Singed.start
      first = Singed.current_flamegraph
      Singed.start

      expect(Singed.current_flamegraph).to be first
    end

    it "does nothing when disabled" do
      Singed.enabled = false
      Singed.start

      expect(Singed.current_flamegraph).to be_nil
      expect(Singed.profiling?).to be false
    end
  end

  describe ".stop" do
    before do
      Singed.enabled = true
      Singed.output_directory = Dir.mktmpdir("singed-spec")
    end

    it "returns nil when not profiling" do
      expect(Singed.stop).to be_nil
    end

    it "stops profiling, saves the result file, and returns the flamegraph with profile data" do
      Singed.start
      # Run some code to generate profile samples
      100.times { 2**10 }
      flamegraph = Singed.stop

      expect(flamegraph).to be_a(Singed::Flamegraph)
      expect(Singed.profiling?).to be false
      expect(Singed.current_flamegraph).to be_nil

      # Profile data is returned (StackProf results hash)
      expect(flamegraph.profile).to be_a(Hash)
      expect(flamegraph.profile).to include(:mode, :version, :interval)
      expect(flamegraph.profile[:mode]).to eq(:wall)
      expect(flamegraph.profile[:samples]).to be >= 0
    end

    it "creates the result file on disk" do
      Singed.start
      100.times { 2**10 }
      flamegraph = Singed.stop

      expect(Pathname(flamegraph.filename)).to exist
    end
  end
end
